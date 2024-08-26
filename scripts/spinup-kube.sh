#!/bin/bash
# Script to deploy, upgrade, and delete k8s on GCP or Civo with runtime tracking, utility auto-detection, and context management

# Set the cloud provider (gcp or civo)
CLOUD_PROVIDER=${1:-gcp}

# Auto-detect the locations of required commands
KUBECTL_CMD=$(which kubectl)

if [ -z "$KUBECTL_CMD" ]; then
  echo "kubectl command not found. Please install it or add it to your PATH."
  exit 1
fi

# Cloud provider specific commands
if [ "$CLOUD_PROVIDER" == "gcp" ]; then
  CLOUD_CMD=$(which gcloud)
  CLUSTER=${CLUSTER:-gcp-kube-dev01}
  ZONE=${ZONE:-us-central1-a}
  NUM_NODES=${NUM_NODES:-3}
elif [ "$CLOUD_PROVIDER" == "civo" ]; then
  CLOUD_CMD=$(which civo)
  CLUSTER=${CLUSTER:-civo-kube-dev01}
else
  echo "Unsupported cloud provider: $CLOUD_PROVIDER"
  exit 1
fi

if [ -z "$CLOUD_CMD" ]; then
  echo "$CLOUD_PROVIDER command not found. Please install it or add it to your PATH."
  exit 1
fi

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
  if [ "$CLOUD_PROVIDER" == "gcp" ]; then
    echo "Creating Kubernetes cluster on GCP..."
    $CLOUD_CMD container clusters create $CLUSTER --zone $ZONE --num-nodes $NUM_NODES
  elif [ "$CLOUD_PROVIDER" == "civo" ]; then
    echo "Creating Kubernetes cluster on Civo..."
    $CLOUD_CMD kubernetes create $CLUSTER --size=g4s.kube.medium --nodes=3 --wait
  fi

  if [ $? -ne 0 ]; then
    echo "Cluster creation failed."
    exit 1
  fi
}

get_credentials() {
  if [ "$CLOUD_PROVIDER" == "gcp" ]; then
    echo "Getting cluster credentials on GCP..."
    $CLOUD_CMD container clusters get-credentials $CLUSTER --zone $ZONE
  elif [ "$CLOUD_PROVIDER" == "civo" ]; then
    echo "Getting cluster credentials on Civo..."
    $CLOUD_CMD kubernetes config $CLUSTER --save --local-path=$HOME/.kube/config
  fi

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
  if [ "$CLOUD_PROVIDER" == "gcp" ]; then
    echo "Fetching the latest Kubernetes version available on GCP..."
    LATEST_VERSION=$($CLOUD_CMD container get-server-config --zone $ZONE | awk '/^ *[0-9]+\.[0-9]+\.[0-9]+/ {print $1}' | head -n 1)
    if [ -z "$LATEST_VERSION" ]; then
      echo "Failed to fetch the latest version."
      exit 1
    fi
    echo "Upgrading Kubernetes cluster on GCP to version $LATEST_VERSION..."
    $CLOUD_CMD container clusters upgrade $CLUSTER --cluster-version $LATEST_VERSION --zone $ZONE --quiet
  elif [ "$CLOUD_PROVIDER" == "civo" ]; then
    echo "Fetching the latest Kubernetes version available on Civo..."
    LATEST_VERSION=$($CLOUD_CMD kubernetes versions | awk '/^ *[0-9]+\.[0-9]+\.[0-9]+/ {print $1}' | head -n 1)
    if [ -z "$LATEST_VERSION" ]; then
      echo "Failed to fetch the latest version."
      exit 1
    fi
    echo "Upgrading Kubernetes cluster on Civo to version $LATEST_VERSION..."
    $CLOUD_CMD kubernetes upgrade $CLUSTER --version=$LATEST_VERSION
  fi

  if [ $? -ne 0 ]; then
    echo "Cluster upgrade failed."
    exit 1
  fi
}

delete_cluster() {
  if [ "$CLOUD_PROVIDER" == "gcp" ]; then
    echo "Deleting Kubernetes cluster on GCP..."
    $CLOUD_CMD container clusters delete $CLUSTER --zone $ZONE --quiet
  elif [ "$CLOUD_PROVIDER" == "civo" ]; then
    echo "Deleting Kubernetes cluster on Civo..."
    $CLOUD_CMD kubernetes remove $CLUSTER --yes
  fi

  if [ $? -ne 0 ]; then
    echo "Cluster deletion failed."
    exit 1
  fi

  echo "Cluster deleted successfully."

  # Remove the context, cluster, and user from the kubeconfig
  kubectl config delete-context $CLUSTER
  kubectl config delete-cluster $CLUSTER
  kubectl config unset users.$CLUSTER
  echo "Removed $CLUSTER configuration from ~/.kube/config"
}

main() {
  START_TIME=$(date +%s)  # Record the start time

  if [ "$2" == "delete" ]; then
    delete_cluster
  else
    create_cluster
    get_credentials
    create_namespace
    upgrade_cluster
  fi

  # Switch to the appropriate context
  kubectl config use-context $(kubectl config get-contexts -o name | grep $CLOUD_PROVIDER)

  calculate_runtime  # Calculate and display the runtime at the end
}

main $@
