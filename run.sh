#!/bin/bash
set -e

cd /root/task

echo "[run] Starting RabbitMQ broker..."
docker compose up -d

echo "[run] Waiting for RabbitMQ to become healthy..."
ATTEMPTS=0
MAX_ATTEMPTS=30
until [ "$(docker inspect -f '{{.State.Health.Status}}' patient-events-rabbitmq 2>/dev/null)" = "healthy" ]; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    echo "[run] ERROR: RabbitMQ did not become healthy in time."
    docker compose logs --tail 50 rabbitmq || true
    exit 1
  fi
  echo "[run] ...still waiting (attempt ${ATTEMPTS}/${MAX_ATTEMPTS})"
  sleep 5
done

echo "[run] RabbitMQ is healthy."

echo "[run] Verifying patient-events topology loaded..."
docker compose exec -T rabbitmq rabbitmqctl list_exchanges -p healthcare name type | grep -q $'patient.events\ttopic' \
  && echo "[run] Found durable topic exchange: patient.events" \
  || { echo "[run] ERROR: patient.events topic exchange not found"; exit 1; }

docker compose exec -T rabbitmq rabbitmqctl list_exchanges -p healthcare name type | grep -q $'patient.events.unrouted\tfanout' \
  && echo "[run] Found alternate exchange: patient.events.unrouted" \
  || { echo "[run] ERROR: patient.events.unrouted exchange not found"; exit 1; }

docker compose exec -T rabbitmq rabbitmqctl list_queues -p healthcare name | grep -q "patient.lab.us.q" \
  && echo "[run] Found queue: patient.lab.us.q" \
  || { echo "[run] ERROR: lab queue not found"; exit 1; }

docker compose exec -T rabbitmq rabbitmqctl list_queues -p healthcare name | grep -q "patient.billing.us.q" \
  && echo "[run] Found queue: patient.billing.us.q" \
  || { echo "[run] ERROR: billing queue not found"; exit 1; }

docker compose exec -T rabbitmq rabbitmqctl list_queues -p healthcare name | grep -q "patient.unrouted.q" \
  && echo "[run] Found queue: patient.unrouted.q" \
  || { echo "[run] ERROR: unrouted queue not found"; exit 1; }

echo "[run] Patient-events topology loaded successfully."
echo "[run] Management UI available on localhost:15672 (vhost: healthcare)."
echo "[run] Use ./seed.sh to publish sample patient events."
echo "[run] Readiness check complete."
