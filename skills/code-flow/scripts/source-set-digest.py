#!/usr/bin/env python3
"""Calculate the canonical SHA-256 digest of a code-flow source-set block."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

START = "<!-- code-flow:source-set:start -->"
END = "<!-- code-flow:source-set:end -->"


def canonical_source_set(raw: bytes) -> bytes:
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ValueError("body must be valid UTF-8") from exc

    text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = text.split("\n")
    starts = [index for index, line in enumerate(lines) if line.strip() == START]
    ends = [index for index, line in enumerate(lines) if line.strip() == END]
    if len(starts) != 1 or len(ends) != 1:
        raise ValueError("body must contain exactly one source-set start and end marker")
    if starts[0] >= ends[0]:
        raise ValueError("source-set markers are out of order")

    payload = "\n".join(lines[starts[0] + 1 : ends[0]]).rstrip("\n") + "\n"
    return payload.encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("body", nargs="?", type=Path, help="Issue body file; stdin when omitted")
    parser.add_argument("--print-canonical", action="store_true", help="Write canonical bytes before the digest")
    args = parser.parse_args()

    raw = args.body.read_bytes() if args.body else sys.stdin.buffer.read()
    try:
        canonical = canonical_source_set(raw)
    except ValueError as exc:
        parser.error(str(exc))

    if args.print_canonical:
        sys.stdout.buffer.write(canonical)
    print(hashlib.sha256(canonical).hexdigest())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
