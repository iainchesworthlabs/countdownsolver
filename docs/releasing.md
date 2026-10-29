# Releasing

A release is a tag `vMAJOR.MINOR.PATCH[-suffix]` on a commit of `develop`. The tag starts
[`release.yml`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.github/workflows/release.yml),
which builds and signs the packages, and then calls the shared `release-publish.yml` of
`icl-common-infra`. That workflow checks the tag, signs the checksums with GPG, makes an SBOM and build
provenance, creates the GitHub Release, and, for a final release, fast-forwards `main` to the tag with the
release bot. The tag is pushed by the maintainer, and the maintainer approves the `release` environment.

## What is in a release

| Platform | Files | Signing |
|---|---|---|
| Windows | `.zip` and an installer `.exe` | `SIGN_WINDOWS`: `false` names them `-unsigned`; `test` signs with the personal CA's certificate and names them `-testsigned`. |
| macOS | `.zip` and `.dmg` | Not signed or notarised yet, so they are named `-unsigned`. |
| Linux | `.tar.gz`, `.zip`, `.deb` and `.rpm`, each with its own Qt | Not signed by the platform. |
| Android | a signed `.apk` and `.aab` | The project's own keystore, held as repository secrets. |
| iOS | not on the release | A build goes to TestFlight when `SIGN_IOS_UPLOAD` is `true`. |

Every file also gets a detached GPG signature (`.asc`), and the release carries `SHA512SUMS` (signed too),
`sbom.spdx.json` and build provenance attestations. [Security](SECURITY.md#verifying-a-release) says how to
check them.

## One-time set-up by the maintainer

1. The public release key is committed as `docs/signing-key.asc`. The shared workflow checks every signature against
   it, and fails if the file is missing. Replace the file, and the fingerprint in `SECURITY.md`, when the key changes.
2. The organisation secrets `REPO_GPG_PRIVATE_KEY`, `REPO_GPG_PASSPHRASE`, `RELEASE_BOT_APP_ID` and
   `RELEASE_BOT_PRIVATE_KEY` are open to this repository.
3. For Android: the repository secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`. Without all four, the Android package is skipped.
4. For iOS (TestFlight):
    - register the App ID `com.iainchesworthlabs.countdownsolver` in the Apple developer portal;
    - make an App Store Connect distribution profile for it and store it as the repository secret
      `IOS_PROVISIONING_PROFILE_BASE64`;
    - create the app record "ICL Countdown Solver" and an internal TestFlight group in App Store Connect;
    - open the organisation secrets `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`,
      `APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID` and `APPSTORE_API_PRIVATE_KEY` to the repository;
    - set the repository variable `SIGN_IOS_UPLOAD` to `true`.
5. For Windows test signing: set `SIGN_WINDOWS` to `test`, with the organisation secrets
   `WIN_TESTSIGN_PFX_BASE64` and `WIN_TESTSIGN_PFX_PASSWORD` open to the repository. `production` and the macOS
   `SIGN_MACOS=production` are refused until a signing service is configured.

The first job of every run, `Release preflight`, lists the names that this run needs and the repository does not
have, without showing any value, and fails early when one is missing.

## Making a pre-release

1. Check that `develop` holds what should be in the release, and that the fragments in `changelog.d/` describe it.
   A pre-release uses the waiting fragments as its notes and does not consume them.
2. Check that the version in `CMakeLists.txt` and `vcpkg.json` is the one the tag names without its suffix. The
   release fails at its first job when they differ.
3. Push the tag from `develop`:

    ```sh
    git switch develop && git pull --ff-only
    git tag v0.3.0-beta.5
    git push origin v0.3.0-beta.5
    ```

4. Approve the `release` environment when the run asks (the Android and iOS jobs, and the publish job, wait for
   it).
5. Read the finished run's summary. The release page lists the files, the iOS build appears in TestFlight a few
   minutes after Apple processes it, and a pre-release does not move `main`.

## Making a final release

1. In a pull request from a `chore/release-<version>` branch, run
   `python3 <icl-common-infra>/scripts/changelog_tool.py assemble --version X.Y.Z --date YYYY-MM-DD`. It moves
   the fragments into a new section of `CHANGELOG.md` and deletes them. This is the one pull request that may edit
   `CHANGELOG.md`.
2. In the same pull request, raise the coverage floors to what the latest `develop` run measured: download its
   `coverage-report` artifact and run `coverage_gate.py --write-floors` as [Testing & coverage](testing.md) shows.
   The floors only go up from one release to the next.
3. Merge it, then tag and push as above with `vX.Y.Z`. The publish job fails a final release whose version has no
   section in `CHANGELOG.md`.
4. After the release succeeds, `main` is at the tag.

## Trying the packaging without a release

```sh
gh workflow run release.yml --ref <branch>
```

This builds and uploads the packages as workflow artifacts and publishes nothing. The version check and the publish
job run for tags only. The Android and iOS jobs still wait for approval of the `release` environment, because they
would reach the signing secrets. With `SIGN_IOS_UPLOAD` set, a run on a branch has Apple validate the iOS build
without uploading it; add `-f upload_testflight=true` to upload it.

## Names the release needs

| For | Names | Kind |
|---|---|---|
| Publishing | `REPO_GPG_PRIVATE_KEY`, `REPO_GPG_PASSPHRASE`, `RELEASE_BOT_APP_ID`, `RELEASE_BOT_PRIVATE_KEY` | organisation secrets |
| Android | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | repository secrets |
| iOS | `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID`, `APPSTORE_API_PRIVATE_KEY` (organisation); `IOS_PROVISIONING_PROFILE_BASE64` (repository) | secrets |
| Windows test signing | `WIN_TESTSIGN_PFX_BASE64`, `WIN_TESTSIGN_PFX_PASSWORD` | organisation secrets |
| Switches | `SIGN_WINDOWS`, `SIGN_MACOS`, `SIGN_IOS_UPLOAD` | repository variables, all `false` to start |
