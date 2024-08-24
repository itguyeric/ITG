#!/bin/bash
# Script to deploy, upgrade, and delete k8s on Civo

CIVO_CMD=/usr/local/bin/civo
KUBECTL_CMD=/usr/bin/kubectl
HELM_CMD=/usr/bin/helm

CLUSTER=${CLUSTER:-itg-dev-01}
NAMESPACE=${NAMESPACE:-itguyeric}
YAML_DIR=${YAML_DIR:-$(pwd)/helm}

create_cluster() {
  echo "Creating Kubernetes cluster on Civo..."
  $CIVO_CMD kubernetes create $CLUSTER --size=g4s.kube.medium --nodes=3 --wait
  if [ $? -ne 0 ]; then
    echo "Cluster creation failed."
    exit 1
  fi
}

get_credentials() {
  echo "Getting cluster credentials..."
  $CIVO_CMD kubernetes config $CLUSTER --save --local-path=$HOME/.kube/config
  if [ $? -ne 0 ]; then
    echo "Failed to get credentials."
    exit 1
  fi
}

create_namespace() {
  echo "Creating namespace $NAMESPACE..."
  $KUBECTL_CMD create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists."
}

add_helm_repos() {
  echo "Adding Helm repositories..."
  $HELM_CMD repo add bitnami https://charts.bitnami.com/bitnami
  $HELM_CMD repo add nextcloud https://nextcloud.github.io/helm/
  $HELM_CMD repo add itzg https://itzg.github.io/minecraft-server-charts/
  $HELM_CMD repo add gloo https://storage.googleapis.com/solo-public-helm
  $HELM_CMD repo update
}

apply_kubernetes_resources() {
  echo "Deploying WordPress..."
  $HELM_CMD install itguyeric-wordpress bitnami/wordpress --namespace $NAMESPACE --set service.type=LoadBalancer

  echo "Deploying Nextcloud..."
  $HELM_CMD install itguyeric-nextcloud nextcloud/nextcloud --namespace $NAMESPACE --set service.type=LoadBalancer

  echo "Deploying Minecraft..."
  $HELM_CMD install itguyeric-minecraft itzg/minecraft --namespace $NAMESPACE --set minecraftServer.eula=true --set service.type=LoadBalancer
}

delete_cluster() {
  echo "Deleting Kubernetes cluster on Civo..."
  $CIVO_CMD kubernetes remove $CLUSTER --yes
  if [ $? -ne 0 ]; then
    echo "Cluster deletion failed."
    exit 1
  fi
  echo "Cluster deleted successfully."
}

main() {
  if [ "$1" == "delete" ]; then
    delete_cluster
  else
    create_cluster
    get_credentials
    create_namespace
    add_helm_repos
    apply_kubernetes_resources
  fi
}

main $1
