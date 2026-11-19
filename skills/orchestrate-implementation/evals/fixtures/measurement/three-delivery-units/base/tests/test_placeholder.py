import unittest


class FixtureLoads(unittest.TestCase):
    def test_package_is_importable(self):
        import src
        self.assertIsNotNone(src)
