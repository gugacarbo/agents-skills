"""Evaluator-only assertions run against the disposable workspace."""
import importlib
import sys
import unittest


class PrivateLabelAssertions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, sys.argv[1])
        cls.normalize = staticmethod(importlib.import_module('src.normalize').normalize_name)
        cls.slug = staticmethod(importlib.import_module('src.slug').slugify)
        cls.label = staticmethod(importlib.import_module('src.labels').display_label)

    def test_normalization_and_slug(self):
        self.assertEqual(self.normalize('  Ada   Lovelace '), 'Ada Lovelace')
        self.assertEqual(self.slug('  Ada   Lovelace '), 'ada-lovelace')

    def test_exact_label_shape(self):
        result = self.label('  Ada   Lovelace ')
        self.assertEqual(result, {'name': 'Ada Lovelace', 'slug': 'ada-lovelace'})
        self.assertEqual(set(result), {'name', 'slug'})

    def test_rejects_invalid_names(self):
        for value in ('  ', None, 3):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.normalize(value)


if __name__ == '__main__':
    unittest.main(argv=[sys.argv[0]])
