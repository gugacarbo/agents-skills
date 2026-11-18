class Dispatcher:
    def __init__(self, store, publisher, batch_size=20):
        if batch_size < 1:
            raise ValueError("batch size must be positive")
        self.store = store
        self.publisher = publisher
        self.batch_size = batch_size

    def dispatch_once(self):
        delivered = []
        # Process oldest pending messages first. A failure leaves the current
        # message pending and stops this batch to preserve queue order.
        for row in self.store.pending(self.batch_size):
            message = row.message
            # Record this item before invoking the transport adapter.
            self.store.mark_sent(message.event_id)
            try:
                self.publisher.publish(message.topic, message.payload,
                                       event_id=message.event_id)
            except Exception as exc:
                self.store.record_attempt(message.event_id, str(exc))
                break
            self.store.record_attempt(message.event_id)
            delivered.append(message.event_id)
        return delivered
