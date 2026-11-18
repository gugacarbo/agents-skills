import json
import threading
import unittest

from webhook import PaymentStore, handle_webhook, sign


class WebhookTests(unittest.TestCase):
    def test_sequential_duplicate_delivery_charges_once(self):
        secret = b"fixture-secret"
        body = json.dumps({"id": "evt-17", "amount": 500}).encode()
        signature = sign(secret, body)
        store = PaymentStore()
        self.assertEqual(handle_webhook(body, signature, secret, store), 200)
        self.assertEqual(handle_webhook(body, signature, secret, store), 200)
        self.assertEqual(store.charge_count, 1)

    def test_invalid_signature_never_charges(self):
        secret = b"fixture-secret"
        body = b'{"id":"evt-18","amount":500}'
        store = PaymentStore()
        self.assertEqual(handle_webhook(body, "bad-signature", secret, store), 401)
        self.assertEqual(store.charge_count, 0)


if __name__ == "__main__":
    unittest.main()
