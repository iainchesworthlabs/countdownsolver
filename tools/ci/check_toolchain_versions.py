#!/usr/bin/env python3
"""Fail when a workflow or install script carries a toolchain version that differs from
.github/toolchain-versions.json.

    python3 tools/ci/check_toolchain_versions.py [--root .]

Each rule names the files it reads, a pattern with one group, and the key whose value the group
must equal. A rule that matches nothing is an error too, so a rewrite that moves a version
cannot leave the check passing without looking at anything.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

WORKFLOWS = [".github/workflows/*.yml"]

# (key path, files, pattern)
RULES = [
    ("qt", ["ci/install-qt.sh"], r'^QT_VERSION="([^"]+)"'),
    ("qt", ["ci/install-qt.ps1"], r'^\$QtVersion = "([^"]+)"'),
    ("qt", WORKFLOWS, r'^\s+version: "(6\.\d+\.\d+)"'),
    ("cmake", WORKFLOWS, r'cmakeVersion: "([^"]+)"'),
    ("ninja", WORKFLOWS, r'ninjaVersion: "([^"]+)"'),
    ("gcc", WORKFLOWS, r"\bg\+\+-(\d+)"),
    ("llvm", WORKFLOWS, r"clang(?:\+\+)?-(\d+)"),
    ("android.ndk", WORKFLOWS, r"ndk;(\d+\.\d+\.\d+)"),
    ("android.jdk", WORKFLOWS, r'java-version: "(\d+)"'),
]


def pinned(pins: dict, key: str) -> str:
    value = pins
    for part in key.split("."):
        value = value[part]
    return str(value)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent.parent)
    root = ap.parse_args().root
    pins = json.loads((root / ".github" / "toolchain-versions.json").read_text(encoding="utf-8"))
    problems: list[str] = []
    for key, globs, pattern in RULES:
        want = pinned(pins, key)
        regex = re.compile(pattern, re.MULTILINE)
        seen = 0
        for glob in globs:
            for path in sorted(root.glob(glob)):
                for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                    for match in regex.finditer(line):
                        seen += 1
                        if match.group(1) != want:
                            problems.append(
                                f"{path.relative_to(root)}:{number}: {key} is {match.group(1)}, "
                                f"toolchain-versions.json says {want}"
                            )
        if seen == 0:
            problems.append(f"rule for {key} matched nothing in {', '.join(globs)}")
    for problem in problems:
        print(problem, file=sys.stderr)
    if not problems:
        print(f"toolchain-versions.json agrees with {len(RULES)} rules")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
