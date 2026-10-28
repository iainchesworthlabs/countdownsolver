# SPDX-FileCopyrightText: 2026 Iain Chesworth
# SPDX-License-Identifier: GPL-3.0-or-later
# ---------------------------------------------------------------------------
# BuildTarget.cmake
#
# Sets COUNTDOWN_BUILD_TARGET to the text the version details show for the
# build: "<os> <arch> (<compiler> <version>)", for example
# "Linux x86_64 (GCC 16.2.0)". CMake knows the target and the compiler when it
# configures, so the sources need no preprocessor tests for them
# (src/lib/include/countdown/build_target.hpp.in).
#
# The mapping keeps what the predefined macros gave before: iOS reads as macOS
# (__APPLE__) and Android as Linux (__linux__).
# ---------------------------------------------------------------------------
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(_countdown_os "Windows")
elseif(CMAKE_SYSTEM_NAME MATCHES "^(Darwin|iOS)$")
    set(_countdown_os "macOS")
elseif(CMAKE_SYSTEM_NAME MATCHES "^(Linux|Android)$")
    set(_countdown_os "Linux")
else()
    set(_countdown_os "unknown-os")
endif()

string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" _countdown_processor)
if(_countdown_processor MATCHES "^(x86_64|amd64|x64)$")
    set(_countdown_arch "x86_64")
elseif(_countdown_processor MATCHES "^(arm64|aarch64)$")
    set(_countdown_arch "arm64")
elseif(_countdown_processor MATCHES "^(x86|i[3-6]86)$")
    set(_countdown_arch "x86")
else()
    set(_countdown_arch "unknown-arch")
endif()

# The first three components of the compiler version, as __clang_major__ and its
# siblings (Clang) or __GNUC__ and its siblings (GCC) give them.
set(_countdown_version "${CMAKE_CXX_COMPILER_VERSION}")
if(_countdown_version MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)")
    set(_countdown_version3 "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}")
else()
    set(_countdown_version3 "${_countdown_version}")
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "^(Clang|AppleClang)$")
    set(_countdown_compiler "Clang ${_countdown_version3}")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(_countdown_compiler "MSVC ${MSVC_VERSION}")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(_countdown_compiler "GCC ${_countdown_version3}")
else()
    set(_countdown_compiler "unknown compiler")
endif()

set(COUNTDOWN_BUILD_TARGET "${_countdown_os} ${_countdown_arch} (${_countdown_compiler})")
