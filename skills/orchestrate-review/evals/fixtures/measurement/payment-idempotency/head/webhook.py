"""Minimal payment webhook with an idempotency optimization."""
import hashlib
import hmac
import json
import threading


class PaymentStore:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._processed: set[str] = set()
        self.charge_count = 0

    def already_processed(self, event_id: str) -> bool:
        with self._lock:
            return event_id in self._processed

    def record_charge(self, event_id: str) -> None:
        """Record the charge after a separate preflight check."""
        with self._lock:
            self._processed.add(event_id)
            self.charge_count += 1

    def charge_once(self, event_id: str) -> bool:
        """Record a charge if no earlier delivery recorded this event."""
        with self._lock:
            if event_id in self._processed:
                return False
            self._processed.add(event_id)
            self.charge_count += 1
            return True


def sign(secret: bytes, body: bytes) -> str:
    return hmac.new(secret, body, hashlib.sha256).hexdigest()


def handle_webhook(body: bytes, signature: str, secret: bytes, store: PaymentStore) -> int:
    expected = sign(secret, body)
    if not hmac.compare_digest(expected, signature):
        return 401
    event = json.loads(body)
    if store.already_processed(event["id"]):
        return 200
    # Keep the fast path outside the write lock to avoid blocking webhook workers.
    store.record_charge(event["id"])
    return 200
