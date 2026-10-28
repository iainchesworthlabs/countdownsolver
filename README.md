# CountdownSolver

[![CI](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/ci.yml/badge.svg)](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/ci.yml)
[![CodeQL](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/codeql.yml/badge.svg)](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/codeql.yml)
[![OSV-Scanner](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/osv-scanner.yml/badge.svg)](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/osv-scanner.yml)
[![Zizmor](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/zizmor.yml/badge.svg)](https://github.com/iainchesworthlabs/countdownsolver/actions/workflows/zizmor.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/iainchesworthlabs/countdownsolver/badge)](https://scorecard.dev/viewer/?uri=github.com/iainchesworthlabs/countdownsolver)
[![Docs](https://img.shields.io/badge/docs-published-2f7d7b)](https://iainchesworthlabs.github.io/countdownsolver/)
[![C++23](https://img.shields.io/badge/C%2B%2B-23-blue)](docs/architecture.md)
[![License: GPL v3+](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](LICENSE)

A cross-platform desktop solver for the two puzzle games from the UK TV
show **[Countdown](https://en.wikipedia.org/wiki/Countdown_(game_show))**:

- **Numbers** — given six numbers and a target (100–999), find an
  arithmetic expression (`+ - x /`, each number at most once, only
  positive whole intermediate results, exact division) that reaches or
  gets closest to the target.
- **Letters** — given nine letters, find the longest dictionary word(s)
  that can be spelled from them.

It'll also generate and solve the show's third game, the **Conundrum**
(unscramble nine letters into one word).

![Numbers page, solved](docs/assets/screenshots/numbers.png)

More screenshots and the full docs live at
**[iainchesworthlabs.github.io/countdownsolver](https://iainchesworthlabs.github.io/countdownsolver/)**.

## Under the hood

All game logic lives in a GUI-free library (`countdown::solver`); a thin
**Qt 6 Quick (QML)** application provides the GUI, wired to the library
through a small `Solver` backend (`src/app/solver.hpp`). See
[Architecture](https://iainchesworthlabs.github.io/countdownsolver/architecture/)
for the modern C++23 features it leans on
(`std::expected`, ranges, deducing `this`, and more) and how the source
tree is laid out.

## Quick start

```sh
git clone https://github.com/iainchesworthlabs/countdownsolver
cd countdownsolver
export ICL_VCPKG_STORE=~/vcpkg-store   # a directory of your choice
cmake --preset windows-msvc-debug -DCMAKE_PREFIX_PATH=<qt>/6.12.0/<arch>
cmake --build --preset windows-msvc-debug
./build/windows-msvc-debug/bin/countdownsolver
```

That needs a C++23 compiler, CMake 4+, Ninja, and Qt 6.12 — see
[Getting started](https://iainchesworthlabs.github.io/countdownsolver/getting-started/)
for the full requirements and every platform's preset. vcpkg comes from the
organisation's fork and is checked out into `ICL_VCPKG_STORE` on the first
configure.

Just want the solver library and tests, no Qt/GUI?

```sh
cmake --preset linux-gcc-debug -DCOUNTDOWN_BUILD_APP=OFF
cmake --build --preset linux-gcc-debug
ctest --preset linux-gcc-debug
```

## Documentation

| | |
| --- | --- |
| [How to play](https://iainchesworthlabs.github.io/countdownsolver/how-to-play/) | Each round explained, and what the results mean |
| [Getting started](https://iainchesworthlabs.github.io/countdownsolver/getting-started/) | Requirements, cloning, first build |
| [Building & packaging](https://iainchesworthlabs.github.io/countdownsolver/building/) | Every preset, sanitizers, `cpack` |
| [Testing & coverage](https://iainchesworthlabs.github.io/countdownsolver/testing/) | TDD, test layers, the coverage floors |
| [Architecture](https://iainchesworthlabs.github.io/countdownsolver/architecture/) | C++23 highlights, source layout |
| [Contributing](https://iainchesworthlabs.github.io/countdownsolver/CONTRIBUTING/) | Branching model, code style, PR process |

## Contributing

Contributions are welcome — see
[CONTRIBUTING.md](https://iainchesworthlabs.github.io/countdownsolver/CONTRIBUTING/)
for the branching model (this project follows
[gitflow](https://nvie.com/posts/a-successful-git-branching-model/):
`develop` for day-to-day work, `main` for tagged releases only) and how
PRs get reviewed. Please also read the
[Code of Conduct](https://iainchesworthlabs.github.io/countdownsolver/CODE_OF_CONDUCT/).

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
