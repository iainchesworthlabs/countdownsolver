#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Iain Chesworth
# SPDX-License-Identifier: GPL-3.0-or-later
"""List which of the names a release needs are missing, before anything is built.

    python3 tools/ci/release_preflight.py

The release workflow passes, for each secret, only whether it is set ("true" or "false"):
the values never reach this script. It reads those flags and the SIGN_* repository
variables from the environment, prints a table of the names (never their values), writes
`android=true|false` to $GITHUB_OUTPUT, and exits 1 when a name a run needs is missing.

What a run needs:

  * a tag run publishes, so it needs the GPG signing secrets, the release bot secrets and
    the committed public key (docs/signing-key.asc);
  * the Android secrets are all-or-nothing: none skips the Android package, a partial set
    is an error;
  * SIGN_IOS_UPLOAD=true needs the Apple secrets;
  * SIGN_WINDOWS=test needs the test-signing certificate secrets, and SIGN_WINDOWS or
    SIGN_MACOS set to production fails, because no signing service is configured for them.

A manual run on a branch publishes nothing, so the publishing names are only reported.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

PUBLISH = ["REPO_GPG_PRIVATE_KEY", "REPO_GPG_PASSPHRASE", "RELEASE_BOT_APP_ID", "RELEASE_BOT_PRIVATE_KEY"]
ANDROID = ["ANDROID_KEYSTORE_BASE64", "ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD"]
IOS = ["IOS_DIST_CERT_P12_BASE64", "IOS_DIST_CERT_PASSWORD", "IOS_PROVISIONING_PROFILE_BASE64",
       "APPSTORE_API_KEY_ID", "APPSTORE_API_ISSUER_ID", "APPSTORE_API_PRIVATE_KEY"]
WINDOWS_TEST = ["WIN_TESTSIGN_PFX_BASE64", "WIN_TESTSIGN_PFX_PASSWORD"]
PUBLIC_KEY = "docs/signing-key.asc"


def present(env: dict[str, str], name: str) -> bool:
    return env.get(name, "").strip().lower() == "true"


def evaluate(env: dict[str, str], public_key_exists: bool) -> tuple[list[str], list[str], bool]:
    """Return (errors, notes, android_enabled)."""
    errors: list[str] = []
    notes: list[str] = []
    is_tag = env.get("REF_TYPE", "") == "tag"

    missing = [n for n in PUBLISH if not present(env, n)]
    if not public_key_exists:
        missing.append(f"{PUBLIC_KEY} (a file in the repository)")
    if missing:
        text = "publishing needs " + ", ".join(missing)
        (errors if is_tag else notes).append(text + ("" if is_tag else " (a run on a branch does not publish)"))

    have = [n for n in ANDROID if present(env, n)]
    android = len(have) == len(ANDROID)
    if have and not android:
        errors.append("the Android signing secrets are partly set; missing "
                      + ", ".join(n for n in ANDROID if not present(env, n)))
    elif not have:
        notes.append("no Android signing secrets are set, so the Android package is skipped")

    if env.get("SIGN_IOS_UPLOAD", "").strip().lower() == "true":
        missing = [n for n in IOS if not present(env, n)]
        if missing:
            errors.append("SIGN_IOS_UPLOAD is true and these are missing: " + ", ".join(missing))

    windows = env.get("SIGN_WINDOWS", "").strip().lower() or "false"
    if windows == "test":
        missing = [n for n in WINDOWS_TEST if not present(env, n)]
        if missing:
            errors.append("SIGN_WINDOWS is test and these are missing: " + ", ".join(missing))
    elif windows == "production":
        errors.append("SIGN_WINDOWS is production, but no Windows signing service is configured")
    elif windows != "false":
        errors.append(f"SIGN_WINDOWS is '{windows}'; it must be false, test or production")

    macos = env.get("SIGN_MACOS", "").strip().lower() or "false"
    if macos == "production":
        errors.append("SIGN_MACOS is production, but macOS signing and notarisation are not configured")
    elif macos != "false":
        errors.append(f"SIGN_MACOS is '{macos}'; it must be false or production")

    return errors, notes, android


def main() -> int:
    root = Path(__file__).resolve().parent.parent.parent
    errors, notes, android = evaluate(dict(os.environ), (root / PUBLIC_KEY).is_file())
    lines = ["### Release preflight", ""]
    lines += [f"- error: {e}" for e in errors] + [f"- note: {n}" for n in notes]
    if not errors and not notes:
        lines.append("- everything this run needs is set")
    summary = "\n".join(lines) + "\n"
    print(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as handle:
            handle.write(summary)
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as handle:
            handle.write(f"android={'true' if android else 'false'}\n")
    for e in errors:
        print(f"::error::{e}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
