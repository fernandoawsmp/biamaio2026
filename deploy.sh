#!/bin/bash

echo ""
echo "==========================="
echo "  BIA - Deploy"
echo "==========================="
echo "Escolha o ambiente:"
echo "1) Sem ALB  (cluster-bia / service-bia)"
echo "2) Com ALB  (cluster-bia-alb / service-bia-alb)"
echo "==========================="
read -p "Opcao: " opcao

case $opcao in
  1)
    CLUSTER="cluster-bia"
    SERVICE="service-bia"
    ./build.sh
    ;;
  2)
    CLUSTER="cluster-bia-alb"
    SERVICE="service-bia-alb"
    ./build.sh "https://bia.fmp.eti.br"
    ;;
  *)
    echo "Opcao invalida!"
    exit 1
    ;;
esac

echo ""
echo "Fazendo deploy no cluster: $CLUSTER / service: $SERVICE"
aws ecs update-service --cluster $CLUSTER --service $SERVICE --force-new-deployment
echo "Deploy iniciado com sucesso!"
