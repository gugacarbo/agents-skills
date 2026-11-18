import unittest
from models import Message, State
from store import OutboxStore
from publisher import RecordingPublisher
from dispatcher import Dispatcher
from recovery import RecoveryWorker

def seed(rows=None):
    store = OutboxStore(rows)
    store.enqueue(Message("evt-1", "invoice.ready", b"one", 1))
    store.enqueue(Message("evt-2", "invoice.ready", b"two", 2))
    return store

class OutboxTests(unittest.TestCase):
    def test_success_marks_sent_and_preserves_event_id(self):
        store = seed(); publisher = RecordingPublisher()
        self.assertEqual(Dispatcher(store, publisher).dispatch_once(), ["evt-1", "evt-2"])
        self.assertEqual([c[2] for c in publisher.calls], ["evt-1", "evt-2"])
        self.assertEqual(store.state("evt-1"), State.SENT)

    def test_duplicate_enqueue_is_idempotent(self):
        store = seed()
        self.assertFalse(store.enqueue(Message("evt-1", "other", b"x", 9)))
        self.assertEqual(len(store.backing_rows), 2)

    def test_pending_order_uses_sequence(self):
        store = OutboxStore()
        store.enqueue(Message("later", "t", b"b", 2))
        store.enqueue(Message("earlier", "t", b"a", 1))
        self.assertEqual([r.message.event_id for r in store.pending(5)], ["earlier", "later"])

    def test_failure_records_attempt_and_stops_batch(self):
        store = seed(); publisher = RecordingPublisher({"evt-1"})
        self.assertEqual(Dispatcher(store, publisher).dispatch_once(), [])
        self.assertEqual(store.backing_rows[0].attempts, 1)
        self.assertEqual(store.backing_rows[0].last_error, "temporary broker outage")
        self.assertEqual(publisher.calls, [])


    def test_pending_limit_truncates_in_sequence_order(self):
        self.assertEqual([r.message.event_id for r in seed().pending(1)], ["evt-1"])

    def test_successful_rows_are_not_pending(self):
        store = seed(); store.mark_sent("evt-1")
        self.assertEqual([r.message.event_id for r in store.pending(10)], ["evt-2"])

    def test_repeated_failure_counts_each_attempt(self):
        store = seed()
        store.record_attempt("evt-1", "down")
        store.record_attempt("evt-1", "still down")
        self.assertEqual(store.backing_rows[0].attempts, 2)

    def test_failure_retains_diagnostic_text(self):
        store = seed(); store.record_attempt("evt-1", "broker unavailable")
        self.assertEqual(store.backing_rows[0].last_error, "broker unavailable")

    def test_publish_receives_original_content(self):
        store = seed(); publisher = RecordingPublisher()
        Dispatcher(store, publisher).dispatch_once()
        self.assertEqual(publisher.calls[0], ("invoice.ready", b"one", "evt-1"))

    def test_unknown_state_lookup_raises_key_error(self):
        with self.assertRaises(KeyError): seed().state("missing")

    def test_empty_store_dispatch_does_not_call_publisher(self):
        publisher = RecordingPublisher()
        self.assertEqual(Dispatcher(OutboxStore(), publisher).dispatch_once(), [])
        self.assertEqual(publisher.calls, [])

    def test_recovery_returns_published_stable_ids(self):
        store = seed(); publisher = RecordingPublisher()
        self.assertEqual(RecoveryWorker(store, publisher).run(), ["evt-1", "evt-2"])

    def test_pending_rows_preserve_event_payload(self):
        row = seed().pending(1)[0]
        self.assertEqual(row.message.payload, b"one")

    def test_enqueue_returns_true_for_new_event(self):
        store = OutboxStore()
        self.assertTrue(store.enqueue(Message("new", "t", b"data", 1)))

    def test_successful_publish_increments_attempt_counter(self):
        store = seed(); Dispatcher(store, RecordingPublisher()).dispatch_once()
        self.assertEqual(store.backing_rows[0].attempts, 1)

    def test_successful_publish_clears_stale_error(self):
        store = seed(); store.record_attempt("evt-1", "temporary")
        Dispatcher(store, RecordingPublisher()).dispatch_once()
        self.assertIsNone(store.backing_rows[0].last_error)

    def test_second_batch_skips_already_sent_first_event(self):
        store = seed(); pub = RecordingPublisher()
        Dispatcher(store, pub).dispatch_once()
        self.assertEqual(Dispatcher(store, pub).dispatch_once(), [])

    def test_pending_does_not_return_sent_entries(self):
        store = seed(); store.mark_sent("evt-2")
        self.assertEqual([row.message.event_id for row in store.pending(5)], ["evt-1"])

    def test_enqueue_duplicate_does_not_add_a_second_row(self):
        store = seed()
        store.enqueue(Message("evt-2", "invoice.ready", b"again", 2))
        self.assertEqual(len(store.backing_rows), 2)

    def test_publisher_failure_is_recorded_without_call_record(self):
        store = seed(); pub = RecordingPublisher({"evt-1"})
        Dispatcher(store, pub).dispatch_once()
        self.assertEqual(pub.calls, [])
        self.assertEqual(store.backing_rows[0].attempts, 1)

    def test_outstanding_event_sequence_is_stable(self):
        store = seed()
        self.assertEqual([r.message.sequence for r in store.pending(10)], [1, 2])

    def test_store_exposes_original_topic_after_retry(self):
        store = seed(); store.record_attempt("evt-1", "down")
        self.assertEqual(store.pending(1)[0].message.topic, "invoice.ready")

if __name__ == "__main__": unittest.main()
