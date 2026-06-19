#!/bin/bash
set -e

echo "[kill] Changing to task directory..."
cd /root/task || true

echo "[kill] Stopping and removing containers..."
docker compose down --remove-orphans || true

echo "[kill] Removing named volumes..."
docker compose down -v || true
docker volume rm task_rabbitmq_data || true

echo "[kill] Removing task-related networks..."
docker network rm task_default || true

echo "[kill] No custom task images are expected; skipping image force-remove unless present."
docker rmi -f rabbitmq:3-management || true

echo "[kill] Pruning Docker system..."
docker system prune -a --volumes -f || true

echo "[kill] Removing task directory..."
rm -rf /root/task || true

echo "Cleanup completed successfully!"
