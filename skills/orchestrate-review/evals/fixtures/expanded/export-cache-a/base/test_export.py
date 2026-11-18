import unittest
from models import Record, ExportRequest, InvalidRequest
from repository import RecordRepository
from cache import PageCache
from exporter import ExportService

def build(capacity=8):
    records = [
        Record("north", "people", "n1", {"name":"Nora", "secret":"N"}, 1),
        Record("north", "orders", "n2", {"total":12, "secret":"N"}, 2),
        Record("south", "people", "s1", {"name":"Sam", "secret":"S"}, 1),
        Record("south", "orders", "s2", {"total":90, "secret":"S"}, 2),
        Record("north", "people", "n3", {"name":"Nia", "secret":"N"}, 3),
    ]
    return ExportService(RecordRepository(records), PageCache(capacity))

class ExportTests(unittest.TestCase):
    def test_modules_are_combined_and_projected(self):
        result = build().export(ExportRequest("north", ["orders", "people"], ["name", "total"]))
        self.assertEqual(result.rows, ({"total":12}, {"name":"Nora"}, {"name":"Nia"}))
        self.assertIsNone(result.next_page)

    def test_page_is_stable_and_scoped(self):
        service = build()
        first = service.export(ExportRequest("north", ["people"], ["name"], 0, 1))
        second = service.export(ExportRequest("north", ["people"], ["name"], 1, 1))
        self.assertEqual(first.rows, ({"name":"Nora"},))
        self.assertEqual(second.rows, ({"name":"Nia"},))
        self.assertIsNone(second.next_page)

    def test_empty_selection(self):
        self.assertEqual(build().export(ExportRequest("north", [], ["name"])).rows, ())

    def test_unknown_fields_are_omitted(self):
        result = build().export(ExportRequest("north", ["people"], ["missing", "name"]))
        self.assertEqual(result.rows[0], {"name":"Nora"})

    def test_requested_module_order_controls_group_order(self):
        service = build()
        people_first = service.export(ExportRequest("north", ["people", "orders"], ["name", "total"]))
        orders_first = service.export(ExportRequest("north", ["orders", "people"], ["name", "total"]))
        self.assertEqual(people_first.rows[0], {"name":"Nora"})
        self.assertEqual(orders_first.rows[0], {"total":12})

    def test_page_size_changes_page_boundaries(self):
        service = build()
        one = service.export(ExportRequest("north", ["people"], ["name"], 0, 1))
        two = service.export(ExportRequest("north", ["people"], ["name"], 0, 2))
        self.assertEqual(len(one.rows), 1)
        self.assertEqual(len(two.rows), 2)

    def test_foreign_tenant_rows_are_not_in_database_page(self):
        page = build().repository.page("north", ["people"], 0, 10)
        self.assertTrue(all(record.tenant_id == "north" for record in page))

    def test_module_discovery_is_tenant_scoped(self):
        service = build()
        self.assertEqual(service.repository.modules_for("north"), ["orders", "people"])
        self.assertEqual(service.repository.modules_for("south"), ["orders", "people"])

    def test_projection_does_not_expose_unselected_secret(self):
        page = build().export(ExportRequest("north", ["people"], ["name"]))
        self.assertTrue(all("secret" not in row for row in page.rows))

    def test_unrequested_module_is_excluded(self):
        page = build().export(ExportRequest("north", ["people"], ["total"]))
        self.assertEqual(page.rows, ({}, {}))

    def test_equal_sort_times_use_record_id_as_tiebreaker(self):
        records = [Record("t", "m", "z", {"id":"z"}, 1), Record("t", "m", "a", {"id":"a"}, 1)]
        page = ExportService(RecordRepository(records), PageCache()).export(ExportRequest("t", ["m"], ["id"]))
        self.assertEqual(page.rows, ({"id":"a"}, {"id":"z"}))

    def test_page_beyond_end_is_empty(self):
        page = build().export(ExportRequest("north", ["people"], ["name"], 20, 1))
        self.assertEqual(page.rows, ())
        self.assertIsNone(page.next_page)

    def test_request_fields_keep_requested_order(self):
        page = build().export(ExportRequest("north", ["people"], ["secret", "name"]))
        self.assertEqual(tuple(page.rows[0]), ("secret", "name"))

    def test_repository_empty_module_set_is_empty(self):
        self.assertEqual(build().repository.page("north", [], 0, 10), [])

    def test_cache_clear_forces_future_lookup(self):
        cache = PageCache(); service = build()
        request = ExportRequest("north", ["people"], ["name"])
        service.cache = cache
        service.export(request); cache.clear()
        self.assertIsNone(cache.get(request))

    def test_cache_reuses_same_tenant_result(self):
        service = build()
        req = ExportRequest("north", ["people"], ["name"])
        self.assertEqual(service.export(req), service.export(req))


    def test_page_size_one_has_continuation_when_rows_remain(self):
        page = build().export(ExportRequest("north", ["people"], ["name"], 0, 1))
        self.assertEqual(page.next_page, 1)

    def test_final_page_has_no_continuation(self):
        page = build().export(ExportRequest("north", ["people"], ["name"], 1, 1))
        self.assertIsNone(page.next_page)

    def test_multiple_tenants_have_independent_record_counts(self):
        service = build()
        self.assertEqual(service.repository.count("north", ["people"]), 2)
        self.assertEqual(service.repository.count("south", ["people"]), 1)

    def test_cache_key_changes_with_field_projection(self):
        cache = PageCache()
        first = ExportRequest("north", ["people"], ["name"])
        second = ExportRequest("north", ["people"], ["secret"])
        self.assertNotEqual(cache.key(first), cache.key(second))

    def test_cache_key_changes_with_page_number(self):
        cache = PageCache()
        first = ExportRequest("north", ["people"], ["name"], 0, 1)
        second = ExportRequest("north", ["people"], ["name"], 1, 1)
        self.assertNotEqual(cache.key(first), cache.key(second))

    def test_request_for_unknown_tenant_returns_empty_rows(self):
        page = build().export(ExportRequest("unknown", ["people"], ["name"]))
        self.assertEqual(page.rows, ())

    def test_projection_can_select_only_secondary_field(self):
        page = build().export(ExportRequest("north", ["orders"], ["total"]))
        self.assertEqual(page.rows, ({"total": 12},))

    def test_module_allowlist_is_applied_before_page_limit(self):
        page = build().repository.page("south", ["orders"], 0, 1)
        self.assertEqual([row.record_id for row in page], ["s2"])

    def test_cache_key_changes_with_page_size(self):
        cache = PageCache()
        a = ExportRequest("north", ["people"], ["name"], 0, 1)
        b = ExportRequest("north", ["people"], ["name"], 0, 2)
        self.assertNotEqual(cache.key(a), cache.key(b))

    def test_repository_count_ignores_unselected_modules(self):
        self.assertEqual(build().repository.count("north", ["people"]), 2)

    def test_page_number_is_zero_based(self):
        service = build()
        self.assertEqual(service.export(ExportRequest("north", ["people"], ["name"], 0, 1)).rows[0], {"name":"Nora"})

    def test_projection_handles_record_missing_selected_field(self):
        page = build().export(ExportRequest("north", ["people"], ["total"]))
        self.assertEqual(page.rows, ({}, {}))

    def test_module_discovery_for_unknown_tenant_is_empty(self):
        self.assertEqual(build().repository.modules_for("unknown"), [])

    def test_page_limit_does_not_mix_module_namespaces(self):
        page = build().repository.page("north", ["orders"], 0, 10)
        self.assertEqual([row.module for row in page], ["orders"])

if __name__ == "__main__": unittest.main()
