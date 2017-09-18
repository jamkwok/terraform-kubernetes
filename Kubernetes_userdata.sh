#!/bin/bash
# Install Kubernetes
apt-get install -y docker.io socat apt-transport-https htop
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
kubectl --namespace kube-system get pods | grep tiller
#Sample helm to mount jenkins
helm install --name my-release --set Persistence.ExistingClaim=task-pv-volume stable/jenkins
