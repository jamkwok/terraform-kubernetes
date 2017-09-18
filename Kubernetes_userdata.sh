#!/bin/bash
apt-get install -y docker.io socat apt-transport-https
curl -s -L https://storage.googleapis.com/kubeadm/kubernetes-xenial-preview-bundle.txz | tar xJv
apt-get install socat
dpkg -i kubernetes-xenial-preview-bundle/*.deb
#Initialise Kubernetes
kubeadm init --use-kubernetes-version v1.4.0-beta.11
#Allows Pod to be run on Master
kubectl taint nodes --all node-role.kubernetes.io/master-
#Setup Pod Network using yml file
kubectl apply -f https://git.io/weave-kube
