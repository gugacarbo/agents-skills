# Notification requirements

Dispatch durable outbox messages to the external publisher. A message may be retried after failures and process restarts; it must not be marked complete until publication succeeds. Retries preserve the stable event ID. Delivery is at least once, and consumers deduplicate by event ID. Exactly-once delivery is not promised. Recovery must preserve queue order among pending messages.
