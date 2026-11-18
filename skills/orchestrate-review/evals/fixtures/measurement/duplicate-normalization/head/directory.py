"""Account directory after extracting a shared email key."""
from email_keys import canonicalize_email


class AccountDirectory:
    def __init__(self, accounts: dict[str, str]) -> None:
        self._accounts = {canonicalize_email(email): name for email, name in accounts.items()}

    def find(self, email: str) -> str | None:
        # Preserve the historical lookup cleanup for callers with pasted addresses.
        return self._accounts.get(email.strip().casefold())
