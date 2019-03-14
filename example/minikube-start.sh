#!/bin/bash

set -eu

KNATIVE_BUILD_VERSION=${KNATIVE_BUILD_VERSION:-v0.4.0}

minikube profile quarkus-app-demo

minikube -p quarkus-app-demo delete

minikube start -p quarkus-app-demo \
  --memory=4096 \
  --cpus=2 \
  --kubernetes-version=v1.12.0 \
  --vm-driver=hyperkit \
  --network-plugin=cni \
  --enable-default-cni \
  --container-runtime=cri-o \
  --bootstrapper=kubeadm \
  --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

kubectl apply --filename https://github.com/knative/build/releases/download/${KNATIVE_BUILD_VERSION}/build.yaml
# TODO just to make sure all missing ones are upated - just to avoid  errors/warnings
kubectl apply --filename https://github.com/knative/build/releases/download/${KNATIVE_BUILD_VERSION}/build.yaml
