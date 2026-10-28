# CI & dependency provisioning

Qt is **not** built from source (it is huge, and Qt's deeply-nested build
tree blows past Windows' 260-char `MAX_PATH` under a normal project path).
Instead we use the **official prebuilt Qt binaries** via
[`aqtinstall`](https://github.com/miurahr/aqtinstall):

- **CI** uses the shared `setup-qt` action of `icl-common-infra`, which wraps
  `jurplel/install-qt-action` (itself a wrapper around aqtinstall) and reads the
  version from the pins file — see [`.github/workflows/ci.yml`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.github/workflows/ci.yml).
- **Locally**, run the matching script below; both install the same
  pinned Qt and print the `CMAKE_PREFIX_PATH` to pass to CMake.

vcpkg still provides Catch2 (the `tests` feature); it no longer provides
Qt.

## Pinned version

The Qt version, with the other toolchain versions, is in
`.github/toolchain-versions.json`. The install scripts here, and any version a
workflow names itself (the compilers, CMake, Ninja, the NDK), must carry the same
value: `tools/ci/check_toolchain_versions.py` checks this in CI (the `Toolchain
pins` job) and fails when a value drifts. Qt is 6.12.0. The compiler floor is
GCC 16, Clang 23, MSVC toolset 14.51 and AppleClang 17.

On Windows the Qt install uses `aqtsource`, a pinned commit of aqtinstall, in
place of the PyPI release: Qt 6.11 and later split the Windows repository per
architecture, which the last release (3.3.0) cannot read. `ci/install-qt.ps1`
installs from the same commit. Linux and macOS keep the release, pinned with
hashes in `ci/requirements-qt.txt`.

The runners are `ubuntu-26.04`, `macos-26` and `windows-2025-vs2026`. The Android
job stays on `ubuntu-24.04`. GCC 16 and Clang 23 are installed by the shared
`setup-gcc` and `setup-llvm` actions.

## Local install

```powershell
# Windows (PowerShell)
pwsh ci/install-qt.ps1                 # installs to C:\Qt by default
```

```bash
# Linux / macOS
./ci/install-qt.sh                     # installs to ~/Qt by default
```

Then configure the app build against it, e.g. on Windows:

```powershell
cmake --preset windows-msvc-debug -DCOUNTDOWN_BUILD_APP=ON `
  -DCMAKE_PREFIX_PATH=C:/Qt/6.12.0/msvc2022_64
cmake --build --preset windows-msvc-debug
```

`CMAKE_PREFIX_PATH` per platform:

| Platform | Path |
| --- | --- |
| Windows (MSVC) | `<outdir>/6.12.0/msvc2022_64` |
| Linux (GCC)    | `<outdir>/6.12.0/gcc_64` |
| macOS          | `<outdir>/6.12.0/macos` |
| Android (arm64-v8a) | `<outdir>/6.12.0/android_arm64_v8a` — also needs a **second**, desktop Qt install (`QT_HOST_PATH`) for cross-build host tools (`moc`, `qmlcachegen`, ...) |
| iOS (device)   | `<outdir>/6.12.0/ios` — macOS/Xcode only |

## Mobile CI jobs

Two build-only, unsigned jobs in [`ci.yml`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.github/workflows/ci.yml)
gate every PR/branch push, mirroring the desktop `build-and-test` jobs but
without a `ctest` step (mobile presets set `COUNTDOWN_BUILD_TESTS=OFF` —
see [Building & packaging](building.md)):

- **`android-build`** (`ubuntu-24.04`): installs a JDK, the Android SDK, the
  NDK that Qt 6.12's Android kit is built with (r27c, 27.2.12479018) with
  platform `android-36` and build-tools 36.0.0, and *two* Qt kits via `setup-qt` — a desktop
  one (`QT_HOST_PATH`) and an Android one (`QT_ANDROID_ROOT`) — then
  configures/builds the `android-arm64-v8a-debug` preset.
- **`ios-build`** (`macos-26`, ships Xcode already): installs a single
  Qt-for-iOS kit, then configures/builds the `ios-debug` preset (unsigned,
  per that preset's `CODE_SIGNING_ALLOWED=NO` cache variables).

## Signed Android release packaging

The [release workflow](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.github/workflows/release.yml)'s
`android-release` job produces a real, signed, distributable package for
Android (alongside the signed-by-checksum Windows/Linux/macOS packages, all with
the same SHA256/512 + Sigstore attestation treatment). This needs the following
**GitHub Secrets** (Settings → Secrets and variables → Actions), which the
maintainer creates — the workflow never sees or stores the underlying key
material beyond the lifetime of a single job run:

| Secret | Purpose |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | The Android release keystore file, base64-encoded (`base64 -w0 release.keystore`) |
| `ANDROID_KEYSTORE_PASSWORD` | The keystore's store password |
| `ANDROID_KEY_ALIAS` | The signing key's alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | The signing key's own password |

If any of these are unset, the Android release job is skipped.

`release.yml`'s `publish` job appends a direct APK link to the GitHub Release
body. See [Installing](installing.md) for the end-user install flow.

There is no iOS release job. The earlier ad-hoc IPA path (a provisioning profile
that listed registered devices, a `manifest.plist` and an install page) has been
withdrawn; iOS testing will go through TestFlight.

**Current verification status** (no Android SDK/NDK, no Mac/Xcode
available in this project's day-to-day dev environment — everything below
was confirmed via real CI runs, not locally):

- **Android is verified end-to-end, including a real intermittent signing
  bug caught and fixed**: `android-release` produces a real signed
  APK/AAB, installed and run on a real tablet emulator (Pixel Tablet
  profile, API 34) — confirming fonts, backspace icon, and RTL layout
  fixes render correctly on the actual device, not just "the build
  succeeded." That same verification also caught a real defect CI's
  file-existence/checksum checks had been silently missing: `android-build/`
  contains both Qt's own automatic unsigned APK (produced during the plain
  "Build" step) and this job's explicitly-signed one side by side, and a
  bare `find ... -name "*.apk"` glob matched both — since `-exec cp` has no
  defined match order, it could silently overwrite the signed APK with the
  unsigned one depending on filesystem traversal order. One real release
  run produced a genuinely unsigned artifact this way (`apksigner verify`:
  "Missing META-INF/MANIFEST.MF") while every existing CI check reported
  success. Fixed by matching only `*-signed.apk`, plus an explicit
  `apksigner verify` step that now fails the job outright if the final
  artifact isn't actually signed - so this class of bug can't silently
  ship again.
- **Extended to phone and portrait, verified the same way**: the signed
  APK from the actual `v0.2.0-beta.1` tagged release was installed on that
  same emulator and driven through all four form factors (tablet
  landscape/portrait, phone landscape/portrait) via `adb shell wm size`/
  `settings put system user_rotation` overrides — each one renders
  correctly, not just the tablet-landscape shape the app originally
  shipped with.
- **`ios-build` (unsigned compile) is verified**: it's passed real Xcode
  CI runs repeatedly since the fixes below landed.
- **iOS is not released.** There is no `ios-release` job; `ios-build` is the only iOS job.

### iOS build fixes (all confirmed via real Xcode CI runs)

**Duplicate-translations-output at the CMake Generate step.** Xcode's "new
build system" refused to generate the project because two targets —
`CountdownSolver_lrelease` and an internally-created
`countdownsolver_qml_countdownsolver_qml_translations` — both independently
referenced the same `countdown_<lang>.qm` output with no dependency between
them. Root-caused (by reading Qt's actual CMake macro source,
`Qt6CoreMacros.cmake`'s `_qt_internal_process_resource()`) to
`qt_add_translations()` self-deferring to run at the end of
`PROJECT_SOURCE_DIR`'s scope by default: when it actually ran, its
`CMAKE_CURRENT_SOURCE_DIR` was the repo root, not `src/app`, which didn't
match `countdownsolver_qml`'s own `SOURCE_DIR` — a mismatch that macro
treats as "attaching this resource from a different directory than the
target lives in," causing it to defensively wrap the embedding in that
extra target instead of attaching directly. Ninja tolerates the resulting
shared output; Xcode's new build system doesn't. Fixed in
`src/app/CMakeLists.txt` by moving the `qt_add_translations()` call to
after `qt_add_executable()` and passing `IMMEDIATE_CALL`, so it runs
synchronously in `src/app`'s own scope instead of deferring to the root.

**`find_package(Qt6)` itself failing** with `Parameters to $<AND> must
resolve to either '0' or '1'`. Around 30 plugin targets (image format
plugins, platform integration plugins, qmltooling debug/profiler plugins,
and the Apple-only permission/TLS/reachability plugins) don't export
`QT_DEFAULT_PLUGIN` at all on the Qt 6.8.3-for-iOS kit (the workaround is kept until
the iOS job shows Qt 6.12's kit does not need it) — Qt's own
plugin-linkage genex reads that property unwrapped as a `$<AND>` operand,
and an unset property is an empty string, not `0`/`1`. Confirmed identical
on both CMake 4.3.3 and 4.0.3, ruling out a CMake-version-specific cause;
no matching upstream Qt bug report found. Worked around in
`src/app/CMakeLists.txt` (`if(IOS)` block right after `find_package`) by
explicitly setting the property on each affected plugin target, using the
desktop Qt 6.8.3 kit's own correct values as the reference.

**Compilation failing** with `'to_chars' is unavailable: introduced in iOS
16.3`. `std::format` (used by libc++) pulls in `std::to_chars`, gated by
iOS SDK availability annotations against whatever deployment target is
set — none was set at all before. Fixed by adding
`CMAKE_OSX_DEPLOYMENT_TARGET=16.3` to the `ios-base` preset in
`CMakePresets.json`.

## Cache hygiene

The repository's Actions cache quota is 10 GB, and GitHub evicts the least
recently used entries once it is exceeded, regardless of what they cost to
rebuild. The big entries here are the Qt installs of `setup-qt`
(`cache: true`): 295 MB on Linux, 324 MB on Windows, 1.2 GB on macOS and 3.4 GB
for iOS. A cache entry is readable only from its own ref, a pull request's base
and the default branch, so an install that `develop` has not stored is stored
again by every pull request under its own ref: on 2026-10-13 one open PR held
5.2 GB of Qt.

[`cache-hygiene.yml`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.github/workflows/cache-hygiene.yml)
runs `ci/prune-actions-cache.sh` when a pull request closes and after a push to
`develop` or `main`, and removes entries whose ref no longer exists (a closed PR,
a deleted branch) and superseded generations (per ref, the newest of each Qt
install family; the newest vcpkg entry per preset). It reports every deletion
and its reason on the run's summary page. A manual dispatch is a dry run unless
`dry_run` is unticked, and `purge` takes a key prefix to reset one family.

The vcpkg binary cache itself (`vcpkg-binary-cache-<preset>-<hash of vcpkg.json>`)
holds only Catch2 (7-24 MB), so it is not worth more than that. The other
repositories in this family (cubeulator, ICL Forge, aqualink-automate) build
OpenCV, ONNX Runtime and OpenSSL and use a different, content-addressed scheme
that is also saved when a job fails; none of it is needed here.

## The pull request gate

[`ci.yml`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.github/workflows/ci.yml)
runs on pull requests, merge-queue entries and pushes to `develop` and `main`.

- `Policy` is the shared `policy.yml`: branch name, commit and pull request text,
  committed-file text, action pinning, REUSE, and the rule that a vcpkg baseline
  named in `vcpkg.json` exists in the organisation's fork. The changelog check is
  switched off until `changelog.d` exists, so a change that users see carries the
  `no-changelog` label.
- `Plan` runs the shared planner over the changed paths with
  `.github/ci/plan.json`. A change to documentation, or to files no build reads,
  skips the build jobs; a path the file does not list builds everything. It also
  checks that the vendored `cmake/icl/` matches the pinned infra commit.
- The build jobs (`build-and-test`, `android-build`, `ios-build`, `coverage`) run
  when the plan asks for them, and not on a draft pull request.
- `Translations complete` and `Toolchain pins` always run.
- `CI Status` aggregates all of these. A failed or cancelled job fails it, and so
  does a skipped job that the plan asked for.

The required checks are `CI Status` and `Scan dependency diff`
(`dependency-review.yml`, which also reports on merge-queue entries, where it
passes without a scan because the pull request was scanned). Other workflows
(CodeQL, OSV-Scanner, zizmor, Scorecard) report findings and do not block.

## Checks before a push

`python3 tools/ci/precheck.py` runs the static checks of the organisation's
shared pull request policy locally. It finds a checkout of `icl-common-infra`
through `ICL_COMMON_INFRA`, or next to this repository.

`cmake/icl/` is a copy of the shared CMake modules. `cmake/icl/SOURCE` holds
the `icl-common-infra` commit it came from, and
`python3 tools/ci/sync_cmake.py --infra <checkout> --check` fails when the
copy differs. Use a checkout at the tag to update it.
