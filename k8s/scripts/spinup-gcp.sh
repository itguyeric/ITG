#!/bin/bash
# Script to deploy and update k8s on GCP

GCLOUD_CMD=/usr/bin/gcloud
KUBECTL_CMD=/usr/bin/kubectl

CLUSTER=${CLUSTER:-itg-dev-01}
ZONE=${ZONE:-us-central1-a}
NUM_NODES=${NUM_NODES:-3}

create_cluster() {
  echo "Creating Kubernetes cluster..."
  $GCLOUD_CMD container clusters create $CLUSTER --zone $ZONE --num-nodes $NUM_NODES > /var/log/gcloud_cluster_creation.log 2>&1
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

main() {
  create_cluster
  get_credentials
  upgrade_cluster
  check_cluster_status
}

main
