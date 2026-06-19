#!/bin/bash
set -e

cd /root/task

# Publishes a small set of sample patient events so you can observe routing
# behavior before and after your topology changes. Safe to run repeatedly.
#
# Routing-key convention:
#   <tenant>.<region>.patient.<event_type>
#
# Producer metadata convention:
#   - content_type: application/json
#   - correlation_id: unique id for tracing each published message
#   - type: logical message family

publish() {
  local routing_key="$1"
  local body="$2"
  local correlation_id="seed-${routing_key//./-}-${RANDOM}"

  docker compose exec -T rabbitmq rabbitmqadmin \
    -V healthcare -u admin -p admin \
    publish exchange=patient.events routing_key="${routing_key}" \
    properties="{\"content_type\":\"application/json\",\"correlation_id\":\"${correlation_id}\",\"type\":\"patient.event\"}" \
    payload="${body}" >/dev/null

  echo "[seed] published rk=${routing_key} correlation_id=${correlation_id}"
}

echo "[seed] Publishing sample patient events..."

# Lab-relevant events: route to patient.lab.us.q only.
publish "westcare.us.patient.lab_result_ready" '{"tenant":"westcare","region":"us","type":"lab_result_ready","patientId":"p-1001"}'
publish "eastcare.us.patient.lab_result_ready" '{"tenant":"eastcare","region":"us","type":"lab_result_ready","patientId":"p-1002"}'

# Billing-relevant events: route to patient.billing.us.q only.
publish "westcare.us.patient.billing_updated" '{"tenant":"westcare","region":"us","type":"billing_updated","patientId":"p-1003"}'
publish "eastcare.us.patient.billing_updated" '{"tenant":"eastcare","region":"us","type":"billing_updated","patientId":"p-1004"}'

# Out-of-region / unrelated events that no US consumer should process:
# route to patient.unrouted.q via the alternate exchange.
publish "westcare.eu.patient.billing_updated" '{"tenant":"westcare","region":"eu","type":"billing_updated","patientId":"p-2001"}'
publish "westcare.eu.patient.lab_result_ready" '{"tenant":"westcare","region":"eu","type":"lab_result_ready","patientId":"p-2002"}'

# Unknown event type with no real consumer interest:
# route to patient.unrouted.q via the alternate exchange.
publish "westcare.us.patient.profile_photo_changed" '{"tenant":"westcare","region":"us","type":"profile_photo_changed","patientId":"p-3001"}'

echo "[seed] Done. Inspect queue depths in the management UI."
echo "[seed] Expected per run after queues start empty: lab=2, billing=2, unrouted=3."
