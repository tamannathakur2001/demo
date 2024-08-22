#!/bin/bash

echo "###################### START DEPLOYMENT ########################"

#################################
#  SCRIPT INPUT ARGS			#
#################################

DOCKER_USERNAME=$1 # Please provide your Docker Username as an script argument
DOCKER_PASSWORD=$2 # Please provide your Docker Password as an script argument

#################################
#  INITIALIZATION STAGE			#
#################################
echo "INITIALIZING VARIABLES"
HELM_RELEASE_NAME="my-apps"
HELM_CHART_PATH="./webapp"
NAMESPACE="village"
APPLICATION1_IMAGE="application1"
APPLICATION2_IMAGE="application2"
APP1_DEPLOYMENT="app1-deployment"
APP2_DEPLOYMENT="app2-deployment"
APP1_IMG_NAME=$DOCKER_USERNAME/$APPLICATION1_IMAGE
APP2_IMG_NAME=$DOCKER_USERNAME/$APPLICATION2_IMAGE

echo "APP1_IMG_NAME: $APP1_IMG_NAME"
echo "APP2_IMG_NAME: $APP2_IMG_NAME"

if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "Namespace $NAMESPACE already exists. Skipping creation."
else
  echo "Creating namespace $NAMESPACE..."
  kubectl create namespace $NAMESPACE
fi

## Using SED command to dynamically chaning the Image Name in docker compose file
sed -i "s|image: [^/]*/$APPLICATION1_IMAGE|image: \"$APP1_IMG_NAME|g" $HELM_CHART_PATH/values.yaml
sed -i "s|image: [^/]*/$APPLICATION2_IMAGE|image: \"$APP2_IMG_NAME|g" $HELM_CHART_PATH/values.yaml

#################################
#        BUILD STAGE			#
#################################
echo "Building Docker images..."
docker build --no-cache -t $APP1_IMG_NAME:latest ./application1
docker build --no-cache -t $APP2_IMG_NAME:latest ./application2

# Pusing image to Docker Hub
echo "Pushing Docker images to Docker Hub..."
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
docker push $APP1_IMG_NAME:latest
docker push $APP2_IMG_NAME:latest

#################################
#    HELM DEPLOY STAGE			#
#################################
# Deploy to Kubernetes using Helm
echo "Deploying to Kubernetes..."
helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART_PATH --namespace $NAMESPACE

echo "Waiting for deployment $APP1_DEPLOYMENT to be available..."
kubectl wait --for=condition=available --timeout=120s deployment/$APP1_DEPLOYMENT

echo "Waiting for deployment $APP2_DEPLOYMENT to be available..."
kubectl wait --for=condition=available --timeout=120s deployment/$APP2_DEPLOYMENT

## Wait for services to be ready
# echo "Waiting for services to be ready..."
# sleep 30

kubectl port-forward svc/app1-service 5000:5000 &
APP1_PID=$!
kubectl port-forward svc/app2-service 5001:5001 &
APP2_PID=$!

sleep 5
echo ""

#################################
#      HTTP RESPONSE STAGE		#
#################################
echo "========Application1 Response ========="
echo "Fetching HTTP response from application1..."
curl -s http://localhost:5000/api/message

echo ""

echo "Fetching HTTP response from application2..."
curl -s http://localhost:5001/api/reverse-message
echo ""

kill $APP1_PID
kill $APP2_PID

#################################
#   CLEAN UP ALL UNUSED IMAGES	#
#################################
# Uncomment code if you wnat to cleanup older unused images from minikube. I used it as while testing there were many unused images got created and that not great.

# echo ""
# echo "y" | docker image prune -a

echo "###################### END ########################"
echo ""