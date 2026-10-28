#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Iain Chesworth
# SPDX-License-Identifier: GPL-3.0-or-later
"""The application identifier is set once, in CMakeLists.txt; the scripts that check a
finished package have to name the same one."""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent


class ApplicationId(unittest.TestCase):
    def test_scripts_agree_with_cmake(self):
        cmake = (ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
        match = re.search(r'set\(COUNTDOWN_APPLICATION_ID "([^"]+)"\)', cmake)
        self.assertIsNotNone(match, "CMakeLists.txt does not set COUNTDOWN_APPLICATION_ID")
        wanted = match.group(1)
        for script in ("packaging/ios/verify_app.sh", "packaging/linux/check-package.sh"):
            text = (ROOT / script).read_text(encoding="utf-8")
            self.assertRegex(text, r'(bundle_id|app_id)="' + re.escape(wanted) + '"', script)


if __name__ == "__main__":
    unittest.main()
