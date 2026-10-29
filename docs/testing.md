# Testing & coverage

Testing is mandatory and drives development (TDD): new behaviour gets a
test alongside it, not after the fact.

- **Unit tests** ([`tests/unit`](https://github.com/iainchesworthlabs/countdownsolver/tree/develop/tests/unit))
  cover each behaviour in isolation, including the Numbers, Letters, and
  Conundrum game logic in `countdown::solver`.
- **Integration tests** ([`tests/integration`](https://github.com/iainchesworthlabs/countdownsolver/tree/develop/tests/integration))
  exercise the file-backed dictionary and full solve pipelines together.
- **App tests** ([`tests/app`](https://github.com/iainchesworthlabs/countdownsolver/tree/develop/tests/app))
  exercise the Qt-facing `Solver` facade with Qt Test.
- **QML tests** ([`tests/qml`](https://github.com/iainchesworthlabs/countdownsolver/tree/develop/tests/qml))
  drive the real `Countdown` QML module (Numbers/Letters/Conundrum/Settings
  pages) headlessly with Qt Quick Test, exercising the QML → `solver` →
  library round trip end to end.

The Catch2 suites are registered with CTest via `catch_discover_tests`, so
each `TEST_CASE` is an individually runnable CTest; the Qt Test/Quick Test
suites each register as a single CTest entry covering every case in that
binary.

```sh
ctest --preset windows-msvc-debug
```

## Coverage

A dedicated `linux-gcc-coverage` preset builds everything with
`--coverage` (gcov) instrumentation:

```console
$ cmake --preset linux-gcc-coverage -DCMAKE_PREFIX_PATH=<qt>/6.12.0/gcc_64
$ cmake --build --preset linux-gcc-coverage
$ QT_QPA_PLATFORM=offscreen ctest --preset linux-gcc-coverage
$ gcovr --root . --filter 'src/.*' --exclude 'src/app/main\.cpp' \
    --exclude-throw-branches --exclude-unreachable-branches \
    --gcov-ignore-errors=no_working_dir_found \
    --object-directory build/linux-gcc-coverage --print-summary
```

If your default `gcov` doesn't match the compiler that built the coverage
data (e.g. building with `g++-16` but `gcov` resolves to an older
default), add `--gcov-executable gcov-<N>` — a version mismatch doesn't
error, it just silently reports 0% coverage.

CI runs this on every push/PR (`Coverage (Linux, GCC)` in `ci.yml`,
pinning `--gcov-executable gcov-16` to match the `g++-16` it builds with)
and holds each component (`src/lib`, `src/app`) to the floors in
`tools/coverage-floors.json` with the shared coverage gate. The default is
**90% of lines and 80% of branches**, and a component's floor may be set lower
or higher. A job fails when a component falls below its floor, or when a source
file belongs to no listed component. The gate prints a hint when a component is
more than a point above its floor: raise the floor in the same pull request
that raised the coverage, so it only goes up. The `coverage-report` artifact of a run
holds `coverage.json`; to raise the floors to what that run measured, rounded down, run

```sh
python3 <icl-common-infra>/scripts/coverage_gate.py --report coverage.json --floors tools/coverage-floors.json --write-floors
```

and commit `tools/coverage-floors.json`. It never lowers a floor.
