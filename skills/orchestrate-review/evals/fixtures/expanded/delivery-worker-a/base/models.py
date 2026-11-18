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
