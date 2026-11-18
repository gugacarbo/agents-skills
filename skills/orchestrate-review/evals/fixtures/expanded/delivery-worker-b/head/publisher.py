class RecordingPublisher:
    def __init__(self, fail_events=()):
        self.fail_events = set(fail_events)
        self.calls = []

    def publish(self, topic, payload, event_id):
        if event_id in self.fail_events:
            raise RuntimeError("temporary broker outage")
        self.calls.append((topic, payload, event_id))
