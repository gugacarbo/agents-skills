class PageCache:
    def __init__(self, capacity=128): self.capacity, self.entries = capacity, {}
    def key(self, request): return (request.tenant_id, tuple(request.modules), tuple(request.fields), request.page, request.page_size)
    def get(self, request): return self.entries.get(self.key(request))
    def put(self, request, value):
        if len(self.entries) >= self.capacity: self.entries.pop(next(iter(self.entries)))
        self.entries[self.key(request)] = value
    def clear(self): self.entries.clear()
