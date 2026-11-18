from collections import OrderedDict
from threading import RLock

class PageCache:
    """Bounded process-local cache for already projected export pages."""
    def __init__(self, capacity=128):
        if capacity < 1:
            raise ValueError("capacity must be positive")
        self.capacity = capacity
        self._entries = OrderedDict()
        self._lock = RLock()

    @staticmethod
    def key(request):
        return (request.tenant_id, tuple(request.modules), tuple(request.fields),
                request.page, request.page_size)

    def get(self, request):
        key = self.key(request)
        with self._lock:
            if key not in self._entries:
                return None
            self._entries.move_to_end(key)
            return self._entries[key]

    def put(self, request, page):
        key = self.key(request)
        with self._lock:
            self._entries[key] = page
            self._entries.move_to_end(key)
            while len(self._entries) > self.capacity:
                self._entries.popitem(last=False)

    def clear(self):
        with self._lock:
            self._entries.clear()
