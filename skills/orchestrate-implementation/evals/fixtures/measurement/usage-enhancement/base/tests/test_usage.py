import unittest

from src.usage import summarize_usage


class UsageTests(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(summarize_usage([]), {})

    def test_sums_and_ignores_blank_user(self):
        self.assertEqual(summarize_usage([
            {"user": "ana", "units": 2}, {"user": "bia", "units": 4},
            {"user": "ana", "units": 3}, {"user": " ", "units": 99},
        ]), {"ana": 5, "bia": 4})

    def test_rejects_invalid_units(self):
        for units in (-1, 1.5, "2", True):
            with self.subTest(units=units), self.assertRaises(ValueError):
                summarize_usage([{"user": "ana", "units": units}])


if __name__ == "__main__":
    unittest.main()
