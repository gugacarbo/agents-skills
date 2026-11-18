import json
import threading
import unittest

from webhook import PaymentStore, handle_webhook, sign


class WebhookTests(unittest.TestCase):
    def test_concurrent_duplicate_delivery_charges_once(self):
        secret = b"fixture-secret"
        body = json.dumps({"id": "evt-17", "amount": 500}).encode()
        signature = sign(secret, body)
        check_barrier = threading.Barrier(12)

        class SynchronizedStore(PaymentStore):
            def already_processed(self, event_id):
                result = super().already_processed(event_id)
                check_barrier.wait()
                return result

        store = SynchronizedStore()
        barrier = threading.Barrier(12)
        statuses = []
        status_lock = threading.Lock()

        def deliver():
            barrier.wait()
            status = handle_webhook(body, signature, secret, store)
            with status_lock:
                statuses.append(status)

        threads = [threading.Thread(target=deliver) for _ in range(12)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()
        self.assertEqual(statuses, [200] * 12)
        self.assertEqual(store.charge_count, 1)

    def test_invalid_signature_never_charges(self):
        secret = b"fixture-secret"
        body = b'{"id":"evt-18","amount":500}'
        store = PaymentStore()
        self.assertEqual(handle_webhook(body, "bad-signature", secret, store), 401)
        self.assertEqual(store.charge_count, 0)


if __name__ == "__main__":
    unittest.main()
