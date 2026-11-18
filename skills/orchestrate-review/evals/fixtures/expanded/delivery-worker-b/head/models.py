from dataclasses import dataclass
from enum import Enum

class State(str, Enum):
    PENDING = "pending"
    SENT = "sent"

@dataclass(frozen=True)
class Message:
    event_id: str
    topic: str
    payload: bytes
    sequence: int

@dataclass
class Entry:
    message: Message
    state: State = State.PENDING
    attempts: int = 0
    last_error: str | None = None

    def record_failure(self, error):
        self.attempts += 1
        self.last_error = str(error)

    def record_success(self):
        self.state = State.SENT
        self.last_error = None

    @property
    def is_pending(self):
        return self.state is State.PENDING
