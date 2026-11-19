"""Evaluator-only assertions run against the disposable workspace."""
import importlib
import sys
import unittest


class PrivateUsageAssertions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, sys.argv[1])
        cls.summarize = staticmethod(importlib.import_module('src.usage').summarize_usage)

    def test_malformed_events(self):
        for event in (None, [], 'bad'):
            with self.subTest(event=event), self.assertRaises(ValueError):
                self.summarize([event])

    def test_missing_user_skips_units_before_validation(self):
        self.assertEqual(self.summarize([{'units': object()}, {'user': ' ', 'units': -1}]), {})

    def test_retained_user_requires_integer_nonnegative_units(self):
        for event in ({'user': 'a'}, {'user': 'a', 'units': True}, {'user': 'a', 'units': -1}):
            with self.subTest(event=event), self.assertRaises(ValueError):
                self.summarize([event])

    def test_preserves_order_and_does_not_mutate(self):
        events = [{'user': 'z', 'units': 1}, {'user': 'a', 'units': 2}, {'user': 'z', 'units': 3}]
        original = [dict(event) for event in events]
        result = self.summarize(events)
        self.assertEqual(list(result), ['z', 'a'])
        self.assertEqual(events, original)


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]])
