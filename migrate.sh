#!/bin/bash

# =============================================
# BIA - Rodar migrations via SSM Port Forwarding
# =============================================
# Prerequisitos:
#   - AWS CLI v2 instalado
#   - Session Manager Plugin instalado
#     https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
#   - npm install executado (para ter o sequelize-cli)
# =============================================

AWS_PROFILE="fmp"
REGION="us-east-1"
RDS_HOST="bia-db.c8rkqog0kvxw.us-east-1.rds.amazonaws.com"
RDS_PORT=5432
LOCAL_PORT=5434
DB_NAME="bia"
DB_USER="postgres"

# Verificar se o Session Manager Plugin esta instalado
if ! command -v session-manager-plugin &> /dev/null; then
  echo "[ERRO] Session Manager Plugin nao encontrado."
  echo "Instale em: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
  exit 1
fi

# Verificar se o sequelize-cli esta disponivel
if ! npx sequelize-cli --version &> /dev/null; then
  echo "[ERRO] sequelize-cli nao encontrado. Rode 'npm install' primeiro."
  exit 1
fi

# Encontrar uma instancia ECS rodando
echo "Buscando instancia ECS..."
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ecs-bia-alb" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text --region $REGION --profile $AWS_PROFILE 2>/dev/null)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
  echo "[ERRO] Nenhuma instancia ECS encontrada com tag 'ecs-bia-alb'."
  exit 1
fi

echo "Instancia encontrada: $INSTANCE_ID"

# Solicitar senha do banco
read -s -p "Senha do banco de dados: " DB_PWD
echo ""

if [ -z "$DB_PWD" ]; then
  echo "[ERRO] Senha nao pode ser vazia."
  exit 1
fi

# Iniciar port forwarding em background
echo "Abrindo tunnel SSM (porta local $LOCAL_PORT -> RDS:$RDS_PORT)..."
aws ssm start-session \
  --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"portNumber\":[\"$RDS_PORT\"],\"localPortNumber\":[\"$LOCAL_PORT\"],\"host\":[\"$RDS_HOST\"]}" \
  --region "$REGION" --profile "$AWS_PROFILE" &> /tmp/ssm-tunnel-bia.log &

SSM_PID=$!

# Funcao para limpar ao sair
cleanup() {
  echo ""
  echo "Encerrando tunnel SSM (PID: $SSM_PID)..."
  kill $SSM_PID 2>/dev/null
  wait $SSM_PID 2>/dev/null
  rm -f /tmp/ssm-tunnel-bia.log
  echo "Pronto."
}
trap cleanup EXIT

# Aguardar tunnel ficar pronto
echo "Aguardando tunnel ficar pronto..."
for i in $(seq 1 15); do
  if nc -z 127.0.0.1 $LOCAL_PORT 2>/dev/null; then
    echo "Tunnel ativo!"
    break
  fi
  if ! kill -0 $SSM_PID 2>/dev/null; then
    echo "[ERRO] Tunnel SSM falhou. Log:"
    cat /tmp/ssm-tunnel-bia.log
    exit 1
  fi
  sleep 1
done

if ! nc -z 127.0.0.1 $LOCAL_PORT 2>/dev/null; then
  echo "[ERRO] Timeout esperando o tunnel. Log:"
  cat /tmp/ssm-tunnel-bia.log
  exit 1
fi

# Rodar migrations
echo ""
echo "==========================="
echo "  Rodando migrations..."
echo "==========================="
echo ""

npx sequelize-cli db:migrate \
  --url "postgresql://$DB_USER:$DB_PWD@127.0.0.1:$LOCAL_PORT/$DB_NAME?sslmode=require"

MIGRATE_EXIT=$?

if [ $MIGRATE_EXIT -eq 0 ]; then
  echo ""
  echo "Migrations executadas com sucesso!"
else
  echo ""
  echo "[ERRO] Migrations falharam (exit code: $MIGRATE_EXIT)"
fi

exit $MIGRATE_EXIT
