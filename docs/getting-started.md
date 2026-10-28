# Getting started

## What you'll need

- A **C++23** compiler: GCC 16+, Clang 23+, MSVC toolset 14.51+ (Visual Studio 2026) or AppleClang 17+.
- **CMake 4.0+** and **Ninja**.
- **Git** and **vcpkg**. vcpkg provides [Catch2](https://github.com/catchorg/Catch2)
  for the test suite, pinned by `builtin-baseline` in `vcpkg.json`. The
  baseline is a commit of the organisation's fork,
  [`iainchesworthlabs/vcpkg`](https://github.com/iainchesworthlabs/vcpkg). Set
  `ICL_VCPKG_STORE` to a directory shared by your checkouts and the first
  configure makes a checkout of that commit there (see
  [Choosing a vcpkg](#choosing-a-vcpkg)).
- **Qt 6.12** — only needed if you want to build the GUI app (the default).
  Qt ships as an official prebuilt package rather than being built from
  source (a from-source Qt build is huge, and on Windows its build tree
  overruns `MAX_PATH`). Install it with
  [`ci/install-qt.ps1`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/ci/install-qt.ps1)
  (Windows) or
  [`ci/install-qt.sh`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/ci/install-qt.sh)
  (Linux/macOS) — both use [aqtinstall](https://github.com/miurahr/aqtinstall).
  See [CI & dependencies](ci.md) for details.
- **Mobile builds only** (Android and iOS — both target tablet and phone,
  portrait and landscape; see [Building & packaging](building.md)): an
  Android SDK + a pinned NDK version plus a Qt-for-Android kit, or Xcode +
  a Qt-for-iOS kit on macOS. Not needed for the desktop presets above.

## Clone

```sh
git clone https://github.com/iainchesworthlabs/countdownsolver
```

## Choosing a vcpkg

A configure that uses vcpkg picks the checkout in this order
(`cmake/icl/IclVcpkgRoot.cmake`):

1. `CMAKE_TOOLCHAIN_FILE`, if you pass one.
2. `COUNTDOWN_VCPKG_ROOT`, a vcpkg checkout you manage yourself.
3. `COUNTDOWN_VCPKG_STORE`, else `ICL_VCPKG_STORE`: a directory that holds one
   checkout per pinned commit, made on first use from a shared clone of the
   fork. Checkouts and repositories that pin the same commit share it.
4. `VCPKG_ROOT`, which CI sets.

With none of these, a preset that needs vcpkg stops and lists the options. A
configure with `-DCOUNTDOWN_BUILD_TESTS=OFF` does not need vcpkg.

## Build and run

```sh
# Configure + build the full project (library, Qt app, tests) with a preset.
# Every preset states its build type explicitly: <toolchain>-debug or
# <toolchain>-release, e.g. windows-msvc-debug, linux-gcc-release,
# linux-clang-debug, macos-clang-release, windows-clang-debug.
cmake --preset windows-msvc-debug -DCMAKE_PREFIX_PATH=<qt>/6.12.0/<arch>
cmake --build --preset windows-msvc-debug

# Run the app.
./build/windows-msvc-debug/bin/countdownsolver
```

Just want the solver library and tests, no Qt/GUI?

```sh
cmake --preset linux-gcc-debug -DCOUNTDOWN_BUILD_APP=OFF
cmake --build --preset linux-gcc-debug
ctest --preset linux-gcc-debug
```

vcpkg bootstraps itself automatically on first configure — no manual
`vcpkg install` step.

For the full picture — every preset, sanitizer flags, and `cpack`
packaging — see [Building & packaging](building.md). For the test suite
and coverage gate, see [Testing & coverage](testing.md).

## Using your own word list

The letters game ships with a bundled dictionary (~122k words). To use your
own instead, drop a newline-delimited word list at `<config-dir>/words.txt`
(the app reports the exact path per platform in **Settings**) and restart
the app.
