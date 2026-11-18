from models import Record

class RecordRepository:
    def __init__(self, records):
        self.records = list(records)

    def page(self, tenant_id, modules, page, page_size):
        # Respect the caller's module priority, then use stable row order.
        order = {}
        for module in modules:
            order.setdefault(module, len(order))
        rows = [record for record in self.records
                if record.tenant_id == tenant_id and record.module in order]
        rows.sort(key=lambda record: (
            order[record.module], record.updated_at, record.record_id))
        start = page * page_size
        return rows[start:start + page_size]

    def count(self, tenant_id, modules):
        allowed = set(modules)
        return sum(1 for record in self.records
                   if record.tenant_id == tenant_id and record.module in allowed)

    def modules_for(self, tenant_id):
        return sorted({record.module for record in self.records
                       if record.tenant_id == tenant_id})
