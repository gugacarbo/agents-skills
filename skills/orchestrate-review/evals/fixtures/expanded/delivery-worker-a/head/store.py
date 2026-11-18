from models import Entry, Message, State

class OutboxStore:
    """Durable-store stand-in; callers pass the backing list across restart."""
    def __init__(self, rows=None):
        self._rows = rows if rows is not None else []

    @property
    def backing_rows(self):
        return self._rows

    def enqueue(self, message):
        if any(row.message.event_id == message.event_id for row in self._rows):
            return False
        self._rows.append(Entry(message))
        self._rows.sort(key=lambda row: row.message.sequence)
        return True

    def pending(self, limit):
        if limit < 1:
            return []
        return [row for row in self._rows if row.state is State.PENDING][:limit]

    def mark_sent(self, event_id):
        row = self._find(event_id)
        row.record_success()

    def record_attempt(self, event_id, error=None):
        row = self._find(event_id)
        if error is None:
            row.attempts += 1
        else:
            row.record_failure(error)

    def state(self, event_id):
        return self._find(event_id).state

    def pending_count(self):
        return sum(1 for row in self._rows if row.is_pending)

    def attempts_for(self, event_id):
        return self._find(event_id).attempts

    def messages(self):
        """Return an immutable view in durable sequence order."""
        return tuple(row.message for row in self._rows)

    def _find(self, event_id):
        for row in self._rows:
            if row.message.event_id == event_id:
                return row
        raise KeyError(event_id)
