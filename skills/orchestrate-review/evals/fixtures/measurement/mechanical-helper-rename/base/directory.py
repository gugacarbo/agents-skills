"""Small account lookup module."""


def normalize_email(value: str) -> str:
    """Return the stable key used by the account index."""
    return value.strip().lower()


class AccountDirectory:
    def __init__(self, accounts: dict[str, str]) -> None:
        self._accounts = {normalize_email(email): name for email, name in accounts.items()}

    def find(self, email: str) -> str | None:
        return self._accounts.get(normalize_email(email))


def display_email(value: str) -> str:
    """Keep display formatting separate from lookup normalization."""
    return value.strip()
