#!/bin/bash
# Script to deploy, upgrade, and delete k8s on GCP

GCLOUD_CMD=/usr/bin/gcloud
KUBECTL_CMD=/usr/bin/kubectl

CLUSTER=${CLUSTER:-itg-dev-01}
ZONE=${ZONE:-us-central1-a}
NUM_NODES=${NUM_NODES:-3}

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

check_cluster_status() {
  echo "Checking cluster status..."
  $KUBECTL_CMD get nodes
  echo ""
  $KUBECTL_CMD get pods --all-namespaces
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
  if [ "$1" == "delete" ]; then
    delete_cluster
  else
    create_cluster
    get_credentials
    upgrade_cluster
    check_cluster_status
  fi
}

main $1
