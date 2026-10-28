// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <ranges>
#include <tuple>
#include <utility>

// Two C++23 range adaptors, std::views::enumerate and std::views::stride, built from
// adaptors that every standard library of the toolchain floor has (zip, iota, filter
// and transform). libc++ lacks the two, and a header that chose between the standard
// views and these by testing a library feature macro would put a preprocessor
// conditional in the library, so every platform uses these.
//
// Replace these with std::views::enumerate and std::views::stride once every
// toolchain in .github/toolchain-versions.json has them.

namespace countdown::detail {

// Yields (index, element) like std::views::enumerate. The index type matches
// enumerate's (the range's difference type).
template <std::ranges::viewable_range R>
[[nodiscard]] constexpr auto enumerate(R&& range) {
    using diff = std::ranges::range_difference_t<R>;
    return std::views::zip(std::views::iota(diff{0}), std::forward<R>(range));
}

// Keeps every step-th element like std::views::stride: pair each element with
// its index, keep the indices divisible by step, then drop the index.
template <std::ranges::viewable_range R>
[[nodiscard]] constexpr auto stride(R&& range, std::ranges::range_difference_t<R> step) {
    using diff = std::ranges::range_difference_t<R>;
    return std::views::zip(std::views::iota(diff{0}), std::forward<R>(range)) |
           std::views::filter(
               [step](const auto& indexed) { return std::get<0>(indexed) % step == 0; }) |
           std::views::transform([](auto&& indexed) -> decltype(auto) {
               return std::get<1>(std::forward<decltype(indexed)>(indexed));
           });
}

}  // namespace countdown::detail
