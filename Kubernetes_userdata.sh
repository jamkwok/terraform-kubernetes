#!/bin/bash
# Install Kubernetes
apt-get install -y docker.io socat apt-transport-https htop git
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
#Initialise Kubernetes
export HOME=/root
kubeadm init
sudo cp /etc/kubernetes/admin.conf /root/
sudo chown $(id -u):$(id -g) /root/admin.conf
export KUBECONFIG=/root/admin.conf
echo 'KUBECONFIG="/root/admin.conf"' >> /etc/environment
#Allows Pod to be run on Master
kubectl taint nodes --all node-role.kubernetes.io/master-
#Setup Pod Network using yml file based on version
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
#Helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
helm init
helm init --upgrade
#Fix namespace issue with helm and kubernetes
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
#Create Persistent volume called task-pv-volume for Pods to mount
mkdir -p /tmp/data
kubectl create -f https://k8s.io/docs/tasks/configure-pod-container/task-pv-volume.yaml
#Create Persistent Volume claim
kubectl create -f https://k8s.io/docs/tasks/configure-pod-container/task-pv-claim.yaml
sleep 45
# Check pods
until [ $(kubectl --namespace kube-system get pods | grep tiller | grep -i running | wc -l) -gt "0" ]; do
  echo "Waiting for Tiller Pod to come up...."
  sleep 5
done
sleep 30
#Install Nodejs
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs
#Sample node
git clone https://github.com/jamkwok/nodejs-sample.git
cd nodejs-sample
docker build -t node-web-app:0.1.0 .
cd /root
helm create node-web-app
#Replace Helm templates service yaml
cat << EOF >> node-web-app/values.yaml
replicaCount: 1
image:
  repository: node-web-app
  tag: 0.1.0
  pullPolicy: IfNotPresent
service:
  name: node-web-app
  type: NodePort
  nodePort: 3000
  externalPort: 80
  internalPort: 80
ingress:
  enabled: false
  hosts:
  annotations:
  tls:
resources: {}
EOF
#Replace Helm templates service Chart
cat << EOF >> node-web-app/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ template "fullname" . }}
  labels:
    app: {{ template "name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.externalPort }}
      nodePort: {{ .Values.service.nodePort }}
  selector:
    app: {{ template "name" . }}
    release: {{ .Release.Name }}
EOF
helm install  --name node-web-app node-web-app
