# Migration to the organisation standard

This page is the plan for moving Countdown Solver into the `iainchesworthlabs` organisation and bringing it in line with the organisation's C++ standard (`icl-common-infra/docs/standard.md`). It is kept up to date until the work is finished, then removed.

Countdown Solver is a working project, not a port. Its naming, code layout and design choices stay. The standard's branching, CI structure, release tooling, repository settings, licensing, identifiers and dependency handling apply.

Status: the plan is agreed and under way. The repository was transferred on 2026-10-28. The last column of the table below says which pull requests have merged.

## Values chosen

| Item | Value | Notes |
|---|---|---|
| Repository | `iainchesworthlabs/countdownsolver` | Transferred from `iainchesworth/CountdownSolver`; history, pull requests, issues, tags and releases move with it. |
| Product name | Countdown Solver | Unchanged. |
| App Store name | ICL Countdown Solver | Unique across the App Store. |
| Bundle and application identifier | `com.iainchesworthlabs.countdownsolver` | The iOS bundle identifier, the Android application id and the macOS bundle identifier. It replaces `org.iainchesworth.countdownsolver`. |
| Saved settings | Qt organisation `CountdownSolver`, application `Countdown Solver` | Unchanged, so saved settings carry over on desktop. |
| Branch model | D1: `develop` is the default branch and the trunk; squash merge through the merge queue; `main` holds releases and is fast-forwarded by the release bot | Gitflow stays in force until the rulesets are applied. |
| Dependencies | vcpkg fork scheme (`iainchesworthlabs/vcpkg`, `IclVcpkgRoot`, `ICL_VCPKG_STORE`); the `deps/vcpkg` submodule is removed | |
| Qt | 6.12.0 (the shared pin), read from `.github/toolchain-versions.json`, installed with the pinned `aqtinstall` commit | Replaces 6.8.3. Snake, Cubeulator and wordjewelssolver use the same pin. |
| Runner images | CI on `ubuntu-26.04`, `macos-26` and `windows-2025-vs2026` | Replaces `ubuntu-24.04` and `macos-15`. |
| Linux package | Qt bundled in the package; built on an `ubuntu-24.04` image with GCC 16 from the toolchain PPA; `check-glibc-floor` and a libstdc++ floor check | The package must start on Ubuntu 24.04 and Debian 13 (glibc 2.39). Same arrangement as Cubeulator. |
| Compiler floor | GCC 16, Clang 23, MSVC 19.51 and 19.52 | Replaces GCC 15 and Clang 21. |
| Layout | `src/lib` and `src/app` stay | The standard's `libs/` and `apps/` layout is not adopted. |
| Code conventions | The repository's own `.clang-format`; naming written into `.clang-tidy` as measured | No renames, no change of brace style. |
| Copyright line | `Copyright (C) 2026 Iain Chesworth` | Licence stays `GPL-3.0-or-later`. |
| Languages | English, French, Spanish, German, Hebrew, Yiddish, Arabic, Japanese, Simplified Chinese (`zh_CN`) | Japanese and Simplified Chinese are new. |
| Changelog | `changelog.d/` fragments, assembled into `CHANGELOG.md` before the tag | |
| Release signing | Organisation GPG key, SHA-512 sums, SPDX SBOM, build provenance attestations | Windows behind `SIGN_WINDOWS`, macOS behind `SIGN_MACOS`. |
| iOS | Signed TestFlight build, internal testing; no IPA on a public release | The ad-hoc path is removed. |
| Android signing key | The current keystore, kept as repository secrets | No organisation upload key yet. |
| Orientation | Not locked on Android or iOS | An exception to standard section 7.7 is to be requested. |
| Coverage gate | 90% lines and 80% branches, with a floor file | Measured today: 92.6% and 86.0%. |
| Preset names | Kept | `tsan`, `fuzz` and `ios-simulator` are added. |

## Order of pull requests

Pull requests target `develop` and are named `feature/` or `bugfix/` until the new rulesets replace the gitflow ones. Each pull request is checked green before the next starts.

| # | Pull request | Depends on | State |
|---|---|---|---|
| 0 | Owner: transfer the repository; organisation settings (below) | | Transfer and the first settings done |
| 1 | This plan (`docs/migration.md`) | 0 | Merged (#115) |
| 2 | Merge #110 (theme, accessibility and locale); close the Dependabot pull request #114 | 0 | Done |
| 3 | Links and badges for the new owner and name; `.git` remote URLs | 0 | |
| 4 | Toolchain pins (`.github/toolchain-versions.json`), vendored `cmake/icl` with `cmake/icl/SOURCE`, `tools/ci` scripts including `precheck.py` | 1 | Merged (#116) |
| 5 | vcpkg fork scheme; remove the submodule; update ClusterFuzzLite | 4 | Merged (#117) |
| 6 | Qt 6.12, compiler floor, runner images; Android NDK and SDK; the Linux package with Qt bundled and built on the 24.04 image | 5 | Toolchain merged (#118); Linux package in review (#119) |
| 7 | Conventions written down: `.clang-tidy` naming, `src/app/.clang-tidy`, `.editorconfig`, `.gitattributes`, `.git-blame-ignore-revs`, Objective-C++ format document | 4 | |
| 8 | Withdraw the ad-hoc iOS path: assets, install page, docs, workflow export | 3 | |
| 9 | One-commit reformat with the repository's own `.clang-format`, listed in `.git-blame-ignore-revs` | 2, 7 | |
| 10 | SPDX headers, `REUSE.toml`, `LICENSES/` | 9 | |
| 11 | `AGENTS.md`, `CONTRIBUTING.md`, `SECURITY.md`, issue forms, pull request template | 7 | |
| 12 | CI on the shared pieces: `CI Status`, policy, zizmor, docs, merge_group triggers, Dependabot (`pip`, `vcpkg`), auto-merge, CodeQL nightly, preprocessor and format checks | 6, 7, 9 | |
| 13 | Owner: apply the D1 rulesets and make `develop` the default branch (after 12) | 12 | |
| 14 | Identifier in one CMake variable; Android application id; Info.plist for TestFlight | 6 | |
| 15 | iOS release job on the shared signing actions, with `release-preflight` | 13, 14 | |
| 16 | Release tooling: `changelog.d`, release workflow on `release-publish.yml`, SBOM, GPG, glibc floor check | 13 | |
| 17 | Documentation: required pages, README badges, releasing and signing | 16 | |

After 15, a validate-only run of the release workflow is read in full before any tag.

## Owner actions

Each is the maintainer's. The settings and the secrets stay with the maintainer.

1. Transfer the repository: `gh api -X POST repos/iainchesworth/CountdownSolver/transfer -f new_owner=iainchesworthlabs -f new_name=countdownsolver`.
2. Check that the fine-grained token behind the Dependabot secret `MERGE_QUEUE_TOKEN` covers the new repository.
3. Apply repository settings, the `release` environment (required reviewer: the maintainer) and variables with `admin/apply.sh` (dry run first). The variables start as `false`.
4. Open the organisation secrets `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID` and `APPSTORE_API_PRIVATE_KEY` to the repository, after the `release` environment exists.
5. In the Apple developer portal: register the App ID `com.iainchesworthlabs.countdownsolver`; make an App Store Connect distribution profile for it with the organisation's Apple Distribution certificate; set it as the repository secret `IOS_PROVISIONING_PROFILE_BASE64`.
6. In App Store Connect: create the app record "ICL Countdown Solver" for that identifier; create an internal TestFlight group.
7. After the TestFlight build runs on the phone: revoke or let expire the ad-hoc provisioning profile, delete the old App ID `org.iainchesworth.countdownsolver` if nothing else uses it, and remove the old app from the phone.
8. Delete the old repository secrets `IOS_DIST_CERTIFICATE_BASE64`, `IOS_DIST_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID` and `APPLE_PROVISIONING_PROFILE_NAME` once the new iOS job has passed.
9. Push the release tags and approve the `release` environment for each release.

## Done on the maintainer's approval

- Delete the four ad-hoc IPAs (`v0.3.0-beta.1` to `v0.3.0-beta.4`) and the three iOS plists (`v0.3.0-beta.2` to `v0.3.0-beta.4`) from the public releases.
- Delete the merged remote and local branches `bugfix/ci-actions-cache-hygiene` and `feature/vcpkg-from-labs-fork`. The worktree and branch for #110 follow once #110 has merged.

## TODO(owner)

- TODO(owner): contact address for `SECURITY.md` and the code of conduct.
- TODO(owner): App Store Connect SKU.
- TODO(owner): where the English word list came from. It is an internally built list that another project also uses. Record the origin and licence in `REUSE.toml`. If it cannot be shown to be redistributable, replace it with an open word list before external testers or a store listing.
- TODO(owner): whether to create an organisation Android upload key. Until then the repository keeps its own `ANDROID_*` secrets.
- TODO(owner): wording of the "unofficial, not affiliated" notice for the README, the About page and the store description. "Countdown" is the name of a television programme.

## Requests to the standard

- An exception to section 7.7 for applications that follow the device orientation.
- Clarify whether `Branch Name` is a required check (section 11.3 against the shipped rulesets).
- `cache-hygiene` as a shared workflow.
- `Q_OS_*` in the preprocessor checker's token list.
- ClusterFuzzLite as an accepted fuzz engine beside the standard's libFuzzer jobs.

## Preserved features

The documentation site and screenshots, `docs/branch-protection.md` (rewritten for the new rulesets), ClusterFuzzLite and `tests/fuzz`, the benchmark tests, the Scorecard and OSV workflows, the README badges, `src/app/DESIGN_SPEC.md`, the translations set-up, the Android install page, and the Actions cache hygiene work.
