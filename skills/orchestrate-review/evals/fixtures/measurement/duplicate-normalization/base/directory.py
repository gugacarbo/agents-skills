"""Shared email key policy before extraction."""


def normalize_email(value: str) -> str:
    return value.strip().lower()


class AccountDirectory:
    def __init__(self, accounts: dict[str, str]) -> None:
        self._accounts = {normalize_email(email): name for email, name in accounts.items()}

    def find(self, email: str) -> str | None:
        return self._accounts.get(normalize_email(email))
