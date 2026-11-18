from dispatcher import Dispatcher

class RecoveryWorker:
    def __init__(self, store, publisher):
        self.store = store
        self.publisher = publisher

    def run(self, batch_size=20):
        return Dispatcher(self.store, self.publisher, batch_size).dispatch_once()
