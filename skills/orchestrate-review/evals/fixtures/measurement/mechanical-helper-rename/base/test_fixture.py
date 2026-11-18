import unittest

from directory import AccountDirectory, normalize_email, display_email


class DirectoryTests(unittest.TestCase):
    def test_original_helper_behavior(self):
        self.assertEqual(normalize_email("  Alice@Example.COM "), "alice@example.com")
        self.assertEqual(normalize_email("  "), "")

    def test_lookup_is_case_and_whitespace_insensitive(self):
        directory = AccountDirectory({"Alice@Example.COM": "Alice"})
        self.assertEqual(directory.find(" alice@example.com "), "Alice")
        self.assertIsNone(directory.find("other@example.com"))

    def test_display_value_does_not_lowercase(self):
        self.assertEqual(display_email(" Alice@Example.COM "), "Alice@Example.COM")


if __name__ == "__main__":
    unittest.main()
