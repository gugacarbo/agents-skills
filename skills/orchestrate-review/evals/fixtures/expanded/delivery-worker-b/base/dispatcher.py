from models import State

class Dispatcher:
    def __init__(self, store, publisher, batch_size=20):
        self.store, self.publisher, self.batch_size = store, publisher, batch_size
    def dispatch_once(self):
        delivered = []
        for row in self.store.pending(self.batch_size):
            try:
                self.publisher.publish(row.message.topic, row.message.payload, event_id=row.message.event_id)
            except Exception as exc:
                self.store.record_attempt(row.message.event_id, str(exc))
                break
            self.store.record_attempt(row.message.event_id)
            self.store.mark_sent(row.message.event_id)
            delivered.append(row.message.event_id)
        return delivered
