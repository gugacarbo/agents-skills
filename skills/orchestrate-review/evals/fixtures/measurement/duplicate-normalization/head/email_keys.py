"""Canonical email key shared by account imports."""


def canonicalize_email(value: str) -> str:
    return value.strip().lower()
