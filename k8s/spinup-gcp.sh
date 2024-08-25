#!/bin/bash
# Script to deploy, upgrade, and delete k8s on GCP with runtime tracking

GCLOUD_CMD=/usr/bin/gcloud
KUBECTL_CMD=/usr/bin/kubectl
HELM_CMD=/usr/bin/helm

CLUSTER=${CLUSTER:-itg-dev-01}
ZONE=${ZONE:-us-central1-a}
NUM_NODES=${NUM_NODES:-3}
NAMESPACE=${NAMESPACE:-itguyeric}
YAML_DIR=${YAML_DIR:-$(pwd)/helm}

# Function to calculate and display the runtime
calculate_runtime() {
  END_TIME=$(date +%s)
  RUNTIME=$((END_TIME - START_TIME))
  HOURS=$((RUNTIME / 3600))
  MINUTES=$(((RUNTIME % 3600) / 60))
  SECONDS=$((RUNTIME % 60))
  printf "Total runtime: %02d:%02d:%02d\n" $HOURS $MINUTES $SECONDS
}

create_cluster() {
  echo "Creating Kubernetes cluster..."
  $GCLOUD_CMD container clusters create $CLUSTER --zone $ZONE --num-nodes $NUM_NODES
  if [ $? -ne 0 ]; then
    echo "Cluster creation failed."
    exit 1
  fi
}

get_credentials() {
  echo "Getting cluster credentials..."
  $GCLOUD_CMD container clusters get-credentials $CLUSTER --zone $ZONE
  if [ $? -ne 0 ]; then
    echo "Failed to get credentials."
    exit 1
  fi
}

create_namespace() {
  echo "Creating namespace $NAMESPACE..."
  $KUBECTL_CMD create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists."
}

upgrade_cluster() {
  echo "Upgrading master..."
  $GCLOUD_CMD container clusters upgrade $CLUSTER --master --zone $ZONE --quiet
  if [ $? -ne 0 ]; then
    echo "Master upgrade failed."
    exit 1
  fi
  
  echo "Upgrading nodes..."
  $GCLOUD_CMD container clusters upgrade $CLUSTER --zone $ZONE --quiet
  if [ $? -ne 0 ]; then
    echo "Node upgrade failed."
    exit 1
  fi
}

add_helm_repos() {
  echo "Adding Helm repositories..."
  $HELM_CMD repo add bitnami https://charts.bitnami.com/bitnami
  $HELM_CMD repo add nextcloud https://nextcloud.github.io/helm/
  $HELM_CMD repo add itzg https://itzg.github.io/minecraft-server-charts/
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
  echo "Deleting Kubernetes cluster..."
  $GCLOUD_CMD container clusters delete $CLUSTER --zone $ZONE --quiet
  if [ $? -ne 0 ]; then
    echo "Cluster deletion failed."
    exit 1
  fi
  echo "Cluster deleted successfully."
}

main() {
  START_TIME=$(date +%s)  # Record the start time

  if [ "$1" == "delete" ]; then
    delete_cluster
  else
    create_cluster
    get_credentials
    create_namespace
    add_helm_repos
    upgrade_cluster
    apply_kubernetes_resources
  fi

  calculate_runtime  # Calculate and display the runtime at the end
}

main $1
