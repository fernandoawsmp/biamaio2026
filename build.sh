#!/bin/bash

ECR_REGISTRY="632813643661.dkr.ecr.us-east-1.amazonaws.com"
VITE_API_URL="${1:-}"

echo "==========================="
echo "  BIA - Build"
echo "==========================="

# Login no ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build da imagem
if [ -n "$VITE_API_URL" ]; then
  echo "VITE_API_URL: $VITE_API_URL"
  docker build --build-arg VITE_API_URL=$VITE_API_URL -t bia .
else
  docker build -t bia .
fi

# Tag e push
docker tag bia:latest $ECR_REGISTRY/bia:latest
docker push $ECR_REGISTRY/bia:latest

echo "Build finalizado com sucesso!"
