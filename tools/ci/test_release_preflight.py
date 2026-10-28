#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Iain Chesworth
# SPDX-License-Identifier: GPL-3.0-or-later
"""Tests for release_preflight.py: python3 -m unittest discover -s tools/ci -p 'test_*.py'"""

import unittest

import release_preflight as rp

ALL_PUBLISH = {n: "true" for n in rp.PUBLISH}
ALL_ANDROID = {n: "true" for n in rp.ANDROID}
ALL_IOS = {n: "true" for n in rp.IOS}


class Preflight(unittest.TestCase):
    def test_tag_with_everything_passes(self):
        errors, _, android = rp.evaluate({"REF_TYPE": "tag", **ALL_PUBLISH, **ALL_ANDROID}, True)
        self.assertEqual(errors, [])
        self.assertTrue(android)

    def test_tag_without_gpg_secret_fails_and_names_it(self):
        env = {"REF_TYPE": "tag", **ALL_PUBLISH}
        env["REPO_GPG_PRIVATE_KEY"] = "false"
        errors, _, _ = rp.evaluate(env, True)
        self.assertEqual(len(errors), 1)
        self.assertIn("REPO_GPG_PRIVATE_KEY", errors[0])
        self.assertNotIn("REPO_GPG_PASSPHRASE", errors[0])

    def test_tag_without_public_key_file_fails(self):
        errors, _, _ = rp.evaluate({"REF_TYPE": "tag", **ALL_PUBLISH}, False)
        self.assertTrue(any("docs/signing-key.asc" in e for e in errors))

    def test_branch_run_only_notes_the_publishing_names(self):
        errors, notes, _ = rp.evaluate({"REF_TYPE": "branch"}, False)
        self.assertEqual(errors, [])
        self.assertTrue(any("publishing needs" in n for n in notes))

    def test_no_android_secrets_skips_android(self):
        errors, notes, android = rp.evaluate({"REF_TYPE": "branch"}, True)
        self.assertEqual(errors, [])
        self.assertFalse(android)
        self.assertTrue(any("Android package is skipped" in n for n in notes))

    def test_partial_android_secrets_fail(self):
        env = {"REF_TYPE": "branch", **ALL_ANDROID}
        env["ANDROID_KEY_ALIAS"] = "false"
        errors, _, android = rp.evaluate(env, True)
        self.assertFalse(android)
        self.assertTrue(any("ANDROID_KEY_ALIAS" in e for e in errors))

    def test_ios_upload_needs_the_apple_names(self):
        env = {"REF_TYPE": "branch", "SIGN_IOS_UPLOAD": "true", **ALL_IOS}
        self.assertEqual(rp.evaluate(env, True)[0], [])
        env["APPSTORE_API_PRIVATE_KEY"] = "false"
        errors, _, _ = rp.evaluate(env, True)
        self.assertTrue(any("APPSTORE_API_PRIVATE_KEY" in e for e in errors))

    def test_ios_upload_off_needs_none_of_them(self):
        self.assertEqual(rp.evaluate({"REF_TYPE": "branch", "SIGN_IOS_UPLOAD": "false"}, True)[0], [])

    def test_windows_test_signing_needs_the_certificate_names(self):
        errors, _, _ = rp.evaluate({"REF_TYPE": "branch", "SIGN_WINDOWS": "test"}, True)
        self.assertTrue(any("WIN_TESTSIGN_PFX_BASE64" in e for e in errors))

    def test_production_signing_is_refused(self):
        errors, _, _ = rp.evaluate({"REF_TYPE": "branch", "SIGN_WINDOWS": "production", "SIGN_MACOS": "production"}, True)
        self.assertEqual(len(errors), 2)

    def test_unknown_variable_values_are_errors(self):
        errors, _, _ = rp.evaluate({"REF_TYPE": "branch", "SIGN_WINDOWS": "yes", "SIGN_MACOS": "test"}, True)
        self.assertEqual(len(errors), 2)


if __name__ == "__main__":
    unittest.main()
