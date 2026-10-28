#!/usr/bin/env python3
"""Fail when a workflow or install script carries a toolchain version that differs from
.github/toolchain-versions.json.

    python3 tools/ci/check_toolchain_versions.py [--root .]

Each rule names the files it reads, a pattern with one group, and the key whose value the group
must equal. A rule that matches nothing is an error too, so a rewrite that moves a version
cannot leave the check passing without looking at anything. The exception is a rule marked
optional: the shared setup actions read the Qt version from the pins file, so a workflow
carries none of its own, and one that does must still agree.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

WORKFLOWS = [".github/workflows/*.yml"]

# (key path, files, pattern, optional)
RULES = [
    ("qt", ["ci/install-qt.sh"], r'^QT_VERSION="([^"]+)"', False),
    ("qt", ["ci/install-qt.ps1"], r'^\$QtVersion = "([^"]+)"', False),
    ("aqtsource", ["ci/install-qt.ps1"], r'^\$AqtSource = "([^"]+)"', False),
    ("qt", WORKFLOWS, r'^\s+version: "(6\.\d+\.\d+)"', True),
    ("cmake", WORKFLOWS, r'cmakeVersion: "([^"]+)"', False),
    ("ninja", WORKFLOWS, r'ninjaVersion: "([^"]+)"', False),
    ("gcc", WORKFLOWS, r"\bg\+\+-(\d+)", False),
    ("llvm", WORKFLOWS, r"clang(?:\+\+)?-(\d+)", False),
    ("android.ndk", WORKFLOWS, r"ndk;(\d+\.\d+\.\d+)", False),
    ("android.platform", WORKFLOWS, r"platforms;(android-\d+)", False),
    ("android.build_tools", WORKFLOWS, r"build-tools;(\d+\.\d+\.\d+)", False),
    ("android.jdk", WORKFLOWS, r'java-version: "(\d+)"', False),
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
    for key, globs, pattern, optional in RULES:
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
        if seen == 0 and not optional:
            problems.append(f"rule for {key} matched nothing in {', '.join(globs)}")
    for problem in problems:
        print(problem, file=sys.stderr)
    if not problems:
        print(f"toolchain-versions.json agrees with {len(RULES)} rules")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
