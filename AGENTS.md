# Instructions for coding agents

This file applies to any automated contributor. Read it before changing the repository. People contributing by hand
will also find it a short list of what the checks expect; [CONTRIBUTING](docs/CONTRIBUTING.md) has the rest.

## Working rules

- Work on a branch named `feature/<slug>` or `bugfix/<slug>`, with a lower-case slug and hyphens. The `Validate gitflow
  branch name` check enforces the prefix. Never commit to `develop` or `main` directly.
- Commit with `git commit -s`. Write the subject in the imperative, 72 characters or fewer, and the body as a plain
  description of what changed and why.
- Before pushing, commit and run `python3 tools/ci/precheck.py`. It runs the static checks of the pull request gate on
  your commits.
- Open pull requests against `develop`. Fill in the pull request template. Squash merge is the only method.
- Build and test with the presets in `CMakePresets.json` (`linux-gcc-debug`, `windows-msvc-debug`,
  `macos-clang-debug`). A change to code runs the preset for the machine at hand, and its tests, before the pull
  request.
- Do not create or edit secrets, tags, releases, repository settings or rulesets. The owner does those.
- Do not change what the program does without the owner's say: the solver's results, the user interface, the word
  lists or the saved settings. Tests that pin them are not edited to make a change pass.
- Do not edit `cmake/icl/`. It is copied from `icl-common-infra`; change that repository and run
  `python3 tools/ci/sync_cmake.py`.

## Code rules

- C++23, extensions off. The standard for all projects is
  [`docs/standard.md`](https://github.com/iainchesworthlabs/icl-common-infra/blob/develop/docs/standard.md) in
  `icl-common-infra`. This repository keeps the conventions it already had, which the standard allows:
  - Format: the repository's `.clang-format` (Google-based, attached braces, 100 columns). Run `clang-format` on
    changed files.
  - Names: [CONTRIBUTING](docs/CONTRIBUTING.md#code-style) lists them, and `.clang-tidy` checks them. The code that QML
    sees under `src/app` is `camelCase`.
  - Return `std::expected` for failures that are expected; do not throw for them.
- Add no new `#if`, `#ifdef` or `#elif` on a platform, a compiler or a library version. CMake chooses the platform
  code (`src/app/platform/<os>/`, [architecture](docs/architecture.md)).
- Qt belongs in `src/app`. `src/lib` (`countdown::solver`) has no GUI and no platform code.
- New behaviour comes with a test ([testing](docs/testing.md)).

## If you change X, update Y

| You change | Also update |
|---|---|
| A public header in `src/lib/include` | The tests, and `docs/architecture.md` when the layout changes |
| A CMake option or preset | `docs/building.md` |
| A toolchain version | `.github/toolchain-versions.json`, then `docs/ci.md`; the `Toolchain pins` job checks the workflows against it |
| A workflow in `.github/workflows` | `docs/ci.md`; pin every `uses:` to a full SHA with a version comment |
| A dependency in `vcpkg.json` | Nothing else; the baseline check and Dependabot cover the fork |
| Test labels, or coverage | `docs/testing.md`, and `tools/coverage-floors.json` (raise a floor when coverage rose) |
| The Linux package files or their dependencies | `packaging/linux/Packaging.cmake`, and `docs/building.md` |
| A string the user sees | `qsTr` or `tr`, then refresh the catalogues with the `update_translations` target ([translations](docs/translations.md)) |
| A language or a word list | `docs/translations.md` and `docs/how-to-play.md` |
