#!/bin/bash

# Define variables
DOCKER_USERNAME="rajeshth05"
DOCKER_PASSWORD="kakuraja@12"
HELM_RELEASE_NAME="my-apps"
HELM_CHART_PATH="./webapp"
NAMESPACE="rajesh1"

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

# Get NodePort for the services
APP1_PORT=$(kubectl get svc/app1-service -o jsonpath='{.spec.ports[0].nodePort}' -n $NAMESPACE)
APP2_PORT=$(kubectl get svc/app2-service -o jsonpath='{.spec.ports[0].nodePort}' -n $NAMESPACE)

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo $MINIKUBE_IP

kubectl port-forward svc/app1-service 5000:5000 &
APP1_PID=$!
kubectl port-forward svc/app2-service 5001:5001 &
APP2_PID=$!

# Print HTTP responses
echo "Fetching HTTP response from app1..."
curl -s http://localhost:5000/api/message
echo ""

echo "Fetching HTTP response from app2..."
curl -s http://localhost:5001/api/reverse-message
echo ""

kill $APP1_PID
kill $APP2_PID