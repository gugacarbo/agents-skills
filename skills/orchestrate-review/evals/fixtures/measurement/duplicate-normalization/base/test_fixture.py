import unittest

from directory import AccountDirectory, normalize_email


class DirectoryTests(unittest.TestCase):
    def test_original_normalizer_trims_and_lowercases(self):
        self.assertEqual(normalize_email("  Alice@Example.COM "), "alice@example.com")

    def test_lookup_uses_same_normalization_as_index(self):
        directory = AccountDirectory({"Alice@Example.COM": "Alice"})
        self.assertEqual(directory.find(" alice@example.com "), "Alice")
        unicode_directory = AccountDirectory({"Straße@example.com": "Unicode"})
        self.assertEqual(unicode_directory.find("STRAẞE@example.com"), "Unicode")


if __name__ == "__main__":
    unittest.main()
