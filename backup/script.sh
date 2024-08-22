#!/bin/bash

# Define variables
DOCKER_USERNAME="rajeshth05"
DOCKER_PASSWORD="kakuraja@12"
HELM_RELEASE_NAME="my-apps"
HELM_CHART_PATH="./helm-chart"
NAMESPACE="default"

# Build and push Docker images
echo "Building Docker images..."
docker build -t $DOCKER_USERNAME/app1:latest ./app1
docker build -t $DOCKER_USERNAME/app2:latest ./app2

echo "Pushing Docker images to Docker Hub..."
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
docker push $DOCKER_USERNAME/app1:latest
docker push $DOCKER_USERNAME/app2:latest

# Deploy to Kubernetes using Helm
echo "Deploying to Kubernetes..."
helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART_PATH --namespace $NAMESPACE

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Get the Cluster IP of the services
APP1_IP=$(kubectl get svc/app1-service -o jsonpath='{.spec.clusterIP}' -n $NAMESPACE)
APP2_IP=$(kubectl get svc/app2-service -o jsonpath='{.spec.clusterIP}' -n $NAMESPACE)

# Print HTTP responses
echo "Fetching HTTP response from app1..."
curl http://$APP1_IP:5000/api/message

echo "Fetching HTTP response from app2..."
curl http://$APP2_IP:5001/api/reverse-message
