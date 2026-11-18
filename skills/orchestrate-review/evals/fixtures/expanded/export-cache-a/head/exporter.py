from models import ExportPage, ExportRequest, InvalidRequest

class ExportService:
    def __init__(self, repository, cache):
        self.repository = repository
        self.cache = cache

    def export(self, request):
        self._validate(request)
        if not request.modules:
            return ExportPage((), None)
        cached = self.cache.get(request)
        if cached is not None:
            return cached
        records = self.repository.page(request.tenant_id, request.modules,
                                      request.page, request.page_size)
        rows = tuple(self._project(record.values, request.fields)
                     for record in records)
        has_more = self.repository.count(request.tenant_id, request.modules) > (
            request.page + 1) * request.page_size
        result = ExportPage(rows, request.page + 1 if has_more else None)
        self.cache.put(request, result)
        return result

    @staticmethod
    def _project(values, fields):
        # The export contract exposes only explicitly selected fields.
        return {name: values[name] for name in fields if name in values}

    @staticmethod
    def _validate(request):
        if not request.tenant_id:
            raise InvalidRequest("tenant is required")
        if request.page < 0 or request.page_size < 1:
            raise InvalidRequest("invalid pagination")
        if len(set(request.fields)) != len(request.fields):
            raise InvalidRequest("duplicate fields")
