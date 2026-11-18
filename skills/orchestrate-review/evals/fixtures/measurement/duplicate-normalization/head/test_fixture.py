import unittest

from directory import AccountDirectory
from email_keys import canonicalize_email


class DirectoryTests(unittest.TestCase):
    def test_shared_canonicalizer_trims_and_lowercases(self):
        self.assertEqual(canonicalize_email("  Alice@Example.COM "), "alice@example.com")

    def test_lookup_uses_same_canonicalization_as_index(self):
        directory = AccountDirectory({"Alice@Example.COM": "Alice"})
        self.assertEqual(directory.find(" alice@example.com "), "Alice")
        self.assertEqual(directory.find("ALICE@EXAMPLE.COM"), "Alice")


if __name__ == "__main__":
    unittest.main()
