# CMake 4 is required; the version range keeps policy behaviour current up to 4.3.
cmake_minimum_required(VERSION 3.28...4.3)

# ---------------------------------------------------------------------------
# vcpkg.
#
# vcpkg.json pins the registry with builtin-baseline. Which vcpkg checkout a
# configure uses for that commit - one shared between checkouts through
# ICL_VCPKG_STORE, a root you name, or the VCPKG_ROOT that CI sets - is decided
# in cmake/icl/IclVcpkgRoot.cmake (docs/building.md), which sets
# CMAKE_TOOLCHAIN_FILE. The presets deliberately do not. The module is included
# by path: cmake/icl is not on CMAKE_MODULE_PATH, so its FindQt6 does not take
# the place of cmake/FindQt6.cmake.
# ---------------------------------------------------------------------------
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/icl/IclVcpkgRoot.cmake")
icl_resolve_vcpkg("${CMAKE_CURRENT_SOURCE_DIR}" COUNTDOWN)

# ---------------------------------------------------------------------------
# Select vcpkg manifest features BEFORE project() (the vcpkg toolchain reads
# VCPKG_MANIFEST_FEATURES when it is loaded at project() time). vcpkg only
# provides Catch2 (the "tests" feature); Qt is a prebuilt dependency found via
# CMAKE_PREFIX_PATH (see ci/ and the README), not built from source.
# ---------------------------------------------------------------------------
if(NOT DEFINED COUNTDOWN_BUILD_TESTS OR COUNTDOWN_BUILD_TESTS)
    list(APPEND VCPKG_MANIFEST_FEATURES "tests")
endif()

project(CountdownSolver
    VERSION 0.3.0
    DESCRIPTION "A solver for the Countdown TV show numbers and letters games"
    HOMEPAGE_URL "https://github.com/iainchesworthlabs/countdownsolver"
    LANGUAGES CXX)

# The application's identifier: the desktop entry and AppStream id on Linux,
# and the name the other platforms' identifiers are written to match.
set(COUNTDOWN_APPLICATION_ID "com.iainchesworthlabs.countdownsolver")

# The part of a release's version after the dash ("beta.5" for 0.3.0-beta.5),
# empty for a final release. The release workflow passes it from the tag; the
# Linux packages use it to sort a pre-release before the release.
set(COUNTDOWN_VERSION_PRERELEASE "" CACHE STRING "Pre-release suffix of the version being packaged")

# ---------------------------------------------------------------------------
# Global language settings: C++23 only, no compiler extensions.
# ---------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile_commands.json for clang-tidy / editors.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Put all runtime artefacts in one place so the Qt app can find its plugins.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CompilerWarnings)
include(Sanitizers)
include(Coverage)

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------
option(COUNTDOWN_BUILD_APP "Build the Qt6 GUI application" ON)
option(COUNTDOWN_BUILD_TESTS "Build the unit and integration test suites" ON)
option(COUNTDOWN_BUILD_FUZZERS "Build libFuzzer harnesses for countdown::solver" OFF)
option(COUNTDOWN_STATIC_LIBSTDCXX
    "Link libstdc++ and libgcc into the Linux app, so it does not need a system libstdc++ as new as the compiler's (the Linux release preset sets it)" OFF)

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
# The library holds ALL of the game logic and is completely GUI-free.
add_subdirectory(src/lib)

# The application is a thin Qt6 GUI layer over the library.
if(COUNTDOWN_BUILD_APP)
    add_subdirectory(src/app)
endif()

if(COUNTDOWN_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Deliberately independent of COUNTDOWN_BUILD_TESTS/tests/CMakeLists.txt:
# fuzz harnesses only need countdown::solver, not Catch2 (the "tests" vcpkg
# manifest feature) or CTest, so they build fine even with tests disabled.
if(COUNTDOWN_BUILD_FUZZERS)
    add_subdirectory(tests/fuzz)
endif()

include(Packaging)

message(STATUS "CountdownSolver ${PROJECT_VERSION}")
message(STATUS "  Build Qt app  : ${COUNTDOWN_BUILD_APP}")
message(STATUS "  Build tests   : ${COUNTDOWN_BUILD_TESTS}")
message(STATUS "  Build fuzzers : ${COUNTDOWN_BUILD_FUZZERS}")
