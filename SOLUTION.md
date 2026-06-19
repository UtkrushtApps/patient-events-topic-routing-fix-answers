# Solution Steps

1. Change the `patient.events` exchange in `definitions.json` from `direct` to durable `topic` so RabbitMQ can route on structured routing-key words instead of a single exact key.

2. Add an alternate exchange to `patient.events` by setting the exchange argument `alternate-exchange` to `patient.events.unrouted`.

3. Declare `patient.events.unrouted` as a durable fanout exchange. This exchange receives any message that was unroutable on `patient.events`.

4. Add a durable `patient.unrouted.q` queue and bind it to `patient.events.unrouted`; because the alternate exchange is fanout, all unrouted messages are captured by that queue.

5. Replace the old `patient.updated` bindings with topic bindings that match the routing-key convention `<tenant>.<region>.patient.<event_type>`: bind `patient.lab.us.q` with `*.us.patient.lab_result_ready` and `patient.billing.us.q` with `*.us.patient.billing_updated`.

6. Keep all queues and exchanges durable so the topology persists across broker restarts and reloads from `definitions.json`.

7. Update or verify producer publishing so messages use the new structured routing keys and include AMQP properties for traceability, at minimum `content_type` set to `application/json` and a unique `correlation_id`.

8. Start RabbitMQ with `./run.sh`. If an older broker volume already exists with the old direct exchange, remove the volume first or run `docker compose down -v` so the new exchange type can be loaded cleanly.

9. Run `./seed.sh` against empty queues and verify the expected depths: 2 messages in `patient.lab.us.q`, 2 messages in `patient.billing.us.q`, and 3 messages in `patient.unrouted.q`.

10. Restart the broker with the same `definitions.json` and confirm the exchange types, bindings, durable queues, and routing behavior remain unchanged.

