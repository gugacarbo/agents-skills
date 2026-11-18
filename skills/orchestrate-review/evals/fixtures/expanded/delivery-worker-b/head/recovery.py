from dispatcher import Dispatcher

class RecoveryWorker:
    def __init__(self, store, publisher):
        self.store = store
        self.publisher = publisher

    def run(self, batch_size=20):
        return Dispatcher(self.store, self.publisher, batch_size).dispatch_once()

    def outstanding(self):
        """Expose pending work for a scheduler without claiming it."""
        return self.store.pending_count()

    def event_ids(self):
        """Stable IDs let operators compare retries across worker restarts."""
        return tuple(message.event_id for message in self.store.messages())
