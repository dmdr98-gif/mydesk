#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-only

"""Check Korean translation coverage and interpolation tokens without a build."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re


ENTRY = re.compile(r'\s*\(("(?:[^"\\]|\\.)*"),\s*("(?:[^"\\]|\\.)*")\),\s*')
PLACEHOLDER = re.compile(r"\{[^{}]*\}|%[A-Za-z_][A-Za-z_0-9]*%")


def read_entries(path, errors):
    entries = {}
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.lstrip().startswith("("):
            continue
        match = ENTRY.fullmatch(line)
        if not match:
            errors.append(f"{path.name}:{line_number}: unsupported translation entry")
            continue
        key, value = (json.loads(token) for token in match.groups())
        if key in entries:
            errors.append(f"{path.name}:{line_number}: duplicate key {key!r}")
        entries[key] = value
    if not entries:
        errors.append(f"{path.name}: no translation entries found")
    return entries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--lang-dir", type=Path,
        default=Path(__file__).resolve().parents[1] / "src" / "lang",
    )
    args = parser.parse_args()
    errors = []
    try:
        template = read_entries(args.lang_dir / "template.rs", errors)
        english = read_entries(args.lang_dir / "en.rs", errors)
        korean = read_entries(args.lang_dir / "ko.rs", errors)
    except (OSError, json.JSONDecodeError) as error:
        parser.exit(1, f"FAIL: {error}\n")

    missing = template.keys() - korean.keys()
    extra = korean.keys() - template.keys()
    empty = {key for key, value in korean.items() if not value.strip()}
    for key in sorted(missing):
        errors.append(f"ko.rs: missing key {key!r}")
    for key in sorted(extra):
        errors.append(f"ko.rs: unknown key {key!r}")
    for key in sorted(empty):
        errors.append(f"ko.rs: empty translation {key!r}")
    for key in sorted(template.keys() & korean.keys() - empty):
        source = english.get(key) or key
        if Counter(PLACEHOLDER.findall(source)) != Counter(PLACEHOLDER.findall(korean[key])):
            errors.append(f"ko.rs: interpolation tokens differ for {key!r}")

    print(f"Korean: {len(korean)}/{len(template)} keys; missing={len(missing)}, "
          f"empty={len(empty)}, extra={len(extra)}")
    for error in errors:
        print(f"FAIL: {error}")
    print("FAIL: Korean localization" if errors else "PASS: Korean localization")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
