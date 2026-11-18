from models import ExportPage

class ExportService:
    def __init__(self, repository, cache): self.repository, self.cache = repository, cache
    def export(self, request):
        if not request.modules: return ExportPage((), None)
        cached = self.cache.get(request)
        if cached is not None: return cached
        records = self.repository.page(request.tenant_id, request.modules, request.page, request.page_size)
        rows = tuple({name: record.values[name] for name in request.fields if name in record.values} for record in records)
        more = self.repository.count(request.tenant_id, request.modules) > (request.page + 1) * request.page_size
        result = ExportPage(rows, request.page + 1 if more else None)
        self.cache.put(request, result)
        return result
