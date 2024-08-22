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
APPLICATION1_IMAGE="application1"
APPLICATION2_IMAGE="application2"
APP1_IMG_NAME=$DOCKER_USERNAME/$APPLICATION1_IMAGE
APP2_IMG_NAME=$DOCKER_USERNAME/$APPLICATION2_IMAGE

echo "APP1_IMG_NAME: $APP1_IMG_NAME"
echo "APP2_IMG_NAME: $APP2_IMG_NAME"

## Using SED command to dynamically chaning the Image Name in docker compose file
# sed -i "s|image: [^/]*/$APPLICATION1_IMAGE|image: $APP1_IMG_NAME|g" docker-compose.yml
# sed -i "s|image: [^/]*/$APPLICATION2_IMAGE|image: $APP2_IMG_NAME|g" docker-compose.yml

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

##############################
       # DEPLOY STAGE			#
##############################
# Deploy to Kubernetes
# echo "Deploying to Kubernetes..."
# docker compose up --detach

# echo "Waiting for services to be ready..."
# sleep 10


##############################
     #HTTP RESPONSE STAGE		#
##############################
# echo "========Application1 Response ========="
# echo "Fetching HTTP response from app1..."
# curl -s http://localhost:5000/$APPLICATION1_IMAGE/msg-response

# echo ""

# echo "========Application2 Response ========="
# echo "Fetching HTTP response from app2..."
# curl -s http://localhost:5001/$APPLICATION2_IMAGE/reverse-msg-response

##############################
  #CLEAN UP ALL UNUSED IMAGES	#
##############################
# Uncomment code if you wnat to cleanup older unused images from minikube. I used it as while testing there were many unused images got created and that not great.

# echo ""
# echo "y" | docker image prune -a

# echo "###################### END ########################"
# echo ""