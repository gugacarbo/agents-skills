from dataclasses import dataclass
from typing import Mapping, Sequence

@dataclass(frozen=True)
class Record:
    tenant_id: str
    module: str
    record_id: str
    values: Mapping[str, object]
    updated_at: int

@dataclass(frozen=True)
class ExportRequest:
    tenant_id: str
    modules: Sequence[str]
    fields: Sequence[str]
    page: int = 0
    page_size: int = 50

@dataclass(frozen=True)
class ExportPage:
    rows: tuple[dict[str, object], ...]
    next_page: int | None

class InvalidRequest(ValueError):
    pass
