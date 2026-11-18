"""Minimal payment webhook with an atomic idempotency boundary."""
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

    def charge_once(self, event_id: str) -> bool:
        """Return true only for the delivery that records the charge."""
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
    store.charge_once(event["id"])
    return 200
