# Contributing

Thanks for taking a look at CountdownSolver! It's a small, fun project, so
this guide is short — the goal is just to save you a round-trip on the
handful of things that aren't obvious from the code.

## Before you start

For anything more than a typo fix, it's worth
[opening an issue](https://github.com/iainchesworthlabs/countdownsolver/issues)
first to say what you're thinking — it avoids duplicated effort and lets
us agree on the approach before you sink time into it.

## Branching model

This project follows [gitflow](https://nvie.com/posts/a-successful-git-branching-model/):

- **`develop`** is the integration branch — target your PR here.
- **`main`** only receives tagged releases; day-to-day work never targets
  it directly.
- Branch names must start with `feature/`, `bugfix/`, `release/`,
  `hotfix/`, or `support/` — a required CI check
  (`Validate gitflow branch name`) enforces this on every PR.

Pick the prefix that matches the work: `feature/` for new functionality,
`bugfix/` for fixing broken or inefficient existing behaviour.

## Set up your build

See [Getting started](getting-started.md) for toolchain requirements and
your first build. `-DCOUNTDOWN_BUILD_APP=OFF` skips Qt entirely if you're
only touching `countdown::solver` and want a faster inner loop.

## Building and running tests

The presets in `CMakePresets.json` are named `<platform>-<toolchain>-<build type>`,
for example `linux-gcc-debug`, `windows-msvc-debug` and `macos-clang-debug`.
Configure, build and test with the one for your machine:

```sh
cmake --preset linux-gcc-debug -DCMAKE_PREFIX_PATH=<qt>
cmake --build --preset linux-gcc-debug
ctest --preset linux-gcc-debug
```

[Building & packaging](building.md) lists every preset, and
[Getting started](getting-started.md) says how to find vcpkg and Qt.

## Commits

- Sign off every commit with `git commit -s`. The sign-off is your statement
  under the [Developer Certificate of Origin](https://developercertificate.org)
  that you may submit the change under the project's licence.
- Write the subject in the imperative, 72 characters or fewer, and the body as
  a plain description of what changed and why.
- Run `python3 tools/ci/precheck.py` before you push. It runs the static checks
  of the pull request gate on your commits.

## Tests are not optional

This project is TDD by convention: new behaviour comes with a test, and
existing behaviour that changes gets its test updated in the same PR. See
[Testing & coverage](testing.md) for where each kind of test lives.

To add a test, put it next to the others of its kind (unit tests in
`tests/unit`, the Qt app's tests in `tests/app`, QML tests in `tests/qml`) and
register it in that directory's `CMakeLists.txt`.

CI holds `src/lib` and `src/app` to the floors in `tools/coverage-floors.json`
(`Coverage (Linux, GCC)`; the default is 90% of lines and 80% of branches) — a PR
that drops a component below its floor fails the check. If your change raises
coverage by more than a point, raise the floor with it.

## Translations

Every string the user sees goes through `qsTr` (QML) or `tr` (C++). After you
add or change one, refresh the catalogues with the `update_translations` target
and translate the new entries; CI fails on an entry still marked unfinished.
[Translations](translations.md) covers updating a language and adding one.

## Code style

- Formatting follows the repo's
  [`.clang-format`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.clang-format) —
  run `clang-format` before committing, or configure your editor to do it
  on save.
- [`.clang-tidy`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.clang-tidy)
  runs as part of the build; warnings are treated as errors, so fix them
  rather than silencing them where you reasonably can.
- Names follow what the code already does, and `.clang-tidy` checks it
  (`readability-identifier-naming`): types are `CamelCase`; functions, methods,
  locals, parameters, namespaces and struct fields are `lower_case`; private and
  protected members end in an underscore (`name_`); constants at namespace or
  class scope are `kCamelCase`; macros are `UPPER_CASE`. The Qt-facing code under
  `src/app` (properties, signals, slots and invokable functions that QML sees) and
  the Qt tests under `tests/app` are `camelCase`, set by the `.clang-tidy` files in
  those directories. Enumerators are not checked: follow the enum you are adding to.
- [`.editorconfig`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.editorconfig)
  carries the indent and line-ending rules for the files `clang-format` does not
  read. A commit that only reformats goes in
  [`.git-blame-ignore-revs`](https://github.com/iainchesworthlabs/countdownsolver/blob/develop/.git-blame-ignore-revs)
  (`git config blame.ignoreRevsFile .git-blame-ignore-revs`).
- Modern C++23 is encouraged over older idioms — see
  [Architecture](architecture.md) for the patterns already in use
  (`std::expected`, ranges, deducing `this`, etc.) and follow their lead.

## Changelog

A pull request that changes what a person using the program can see adds a
fragment to `changelog.d/` (see its `README.md` for the format). Do not edit
`CHANGELOG.md`: a pull request before each final release assembles the fragments
into it. A pull request that changes only documentation, tests or tooling carries
the `no-changelog` label instead.

## Opening a pull request

1. Push your `feature/*` or `bugfix/*` branch and open a PR against
   `develop`.
2. Make sure CI is green: build matrix, coverage gate, CodeQL, and the
   branch-name check all have to pass before a PR can merge.
3. Keep PRs focused — a bug fix doesn't need to carry an unrelated
   refactor along with it.

That's it. If anything here is unclear or out of date, flagging it in an
issue is itself a welcome contribution.
