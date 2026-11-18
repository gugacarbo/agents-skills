# Export requirements

The export API returns one page of records for the authenticated tenant, preserving requested module order and field projection. Records from another tenant must never appear, including when the shared page cache is warm. Cache identity must distinguish all inputs that affect the response. Pagination uses a stable, per-tenant ordering. An empty module selection returns an empty page.
