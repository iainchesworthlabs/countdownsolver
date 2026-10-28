// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#include <countdown/build_target.hpp>
#include <countdown/version.hpp>

#include <format>
#include <string>

namespace countdown {

namespace {

// OS/architecture/compiler this binary was built for. CMake works the text out when it
// configures (cmake/BuildTarget.cmake), so nothing here tests a predefined macro.
std::string build_target() {
    return std::string{build_target_text};
}

}  // namespace

std::string version_details() {
    return std::format(
        "CountdownSolver {}\n"
        "  release: {}\n"
        "  commit:  {}\n"
        "  branch:  {}\n"
        "  target:  {}{}",
        version_string, git_describe, git_commit_full, git_branch, build_target(),
        git_dirty ? "\n  state:   dirty (uncommitted changes)" : "");
}

}  // namespace countdown
