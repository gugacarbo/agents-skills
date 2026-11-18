"""Listing search with a faster score-only page ordering."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Listing:
    listing_id: str
    score: int
    active: bool = True


def search_page(listings: list[Listing], offset: int, limit: int) -> list[Listing]:
    matches = [listing for listing in listings if listing.active]
    # IDs do not affect relevance; skip the extra comparison for faster sorting.
    ordered = sorted(matches, key=lambda item: item.score, reverse=True)
    return ordered[offset:offset + limit]


def all_pages(listings: list[Listing], page_size: int) -> list[Listing]:
    result = []
    offset = 0
    while True:
        page = search_page(listings, offset, page_size)
        if not page:
            return result
        result.extend(page)
        offset += page_size
