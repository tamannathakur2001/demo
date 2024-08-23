#!/bin/bash

echo "###################### START DEPLOYMENT ########################"

#################################
#  SCRIPT INPUT ARGS                    #
#################################

DOCKER_USERNAME=$1 # Please provide your Docker Username as an script argument
DOCKER_PASSWORD=$2 # Please provide your Docker Password as an script argument
NAMESPACE=$3 # Provide NAMESPACE as per your choice that you wanted to deploy this aplication to.

#################################
#  INITIALIZATION STAGE                 #
#################################
echo "INITIALIZING VARIABLES"
MINIKUBE_IP=$(minikube ip)
HELM_RELEASE_NAME="my-apps"
HELM_CHART_PATH="./webapp"
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
sed -i "s|MINIKUBE_IP: .*|MINIKUBE_IP: \"$MINIKUBE_IP\"|g" $HELM_CHART_PATH/templates/app-conf.yml
#################################
#        BUILD STAGE                    #
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
#    HELM DEPLOY STAGE                  #
#################################
# Deploy to Kubernetes using Helm
echo "Deploying to Kubernetes..."
helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART_PATH --namespace $NAMESPACE

echo "Waiting for deployment $APP1_DEPLOYMENT to be available..."
kubectl wait --for=condition=available --timeout=120s deployment/$APP1_DEPLOYMENT -n $NAMESPACE

echo "Waiting for deployment $APP2_DEPLOYMENT to be available..."
kubectl wait --for=condition=available --timeout=120s deployment/$APP2_DEPLOYMENT -n $NAMESPACE

APP1_NODEPORT=$(kubectl get service app1-service -o jsonpath='{.spec.ports[0].nodePort}' -n $NAMESPACE)
APP2_NODEPORT=$(kubectl get service app2-service -o jsonpath='{.spec.ports[0].nodePort}' -n $NAMESPACE)


#################################
#      HTTP RESPONSE STAGE              #
#################################
echo "========Application1 Response ========="
echo "Fetching HTTP response from application1..."
curl -s http://${MINIKUBE_IP}:${APP1_NODEPORT}/application1/msg-response

echo ""

echo "Fetching HTTP response from application2..."
curl -s http://${MINIKUBE_IP}:${APP2_NODEPORT}/application2/reverse-msg-response
echo ""

#################################
#   CLEAN UP ALL UNUSED IMAGES  #
#################################
# Uncomment code if you wnat to cleanup older unused images from minikube. I used it as while testing there were many unused images got created and that not great.

# echo ""
# echo "y" | docker image prune -a

echo "###################### END ########################"
echo ""
