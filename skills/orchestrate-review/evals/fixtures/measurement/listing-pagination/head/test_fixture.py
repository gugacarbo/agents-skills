import unittest

from listing import Listing, all_pages, search_page


class ListingTests(unittest.TestCase):
    def setUp(self):
        self.listings = [
            Listing("L3", 10),
            Listing("L1", 10),
            Listing("L2", 10),
            Listing("inactive", 99, active=False),
            Listing("L4", 8),
        ]

    def test_ties_use_listing_id_as_secondary_order(self):
        self.assertEqual([x.listing_id for x in search_page(self.listings, 0, 1)], ["L3"])

    def test_pages_are_complete_and_nonoverlapping(self):
        pages = [all_pages(self.listings, size) for size in (1, 2, 3)]
        expected = ["L3", "L1", "L2", "L4"]
        self.assertEqual([[x.listing_id for x in page] for page in pages], [expected] * 3)


if __name__ == "__main__":
    unittest.main()
