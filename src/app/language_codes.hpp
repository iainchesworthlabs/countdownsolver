// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QLocale>
#include <QString>

#include <span>

namespace countdown::app {

struct LanguageInfo {
    const char* code;
    const char* nativeName;
};

// "en" (no .qm - the untranslated source strings are already English) first,
// then every language this app ships translations for (see
// src/app/translations/). Names are UTF-8 literals in each language's own
// script, not the current UI language, so a user can recognise their entry
// regardless of what the UI currently shows.
[[nodiscard]] std::span<const LanguageInfo> supported_languages() noexcept;

[[nodiscard]] bool is_supported(const QString& code);

// Maps a system locale to one of supported_languages(), or "en" if
// unsupported - so an unrecognised system locale falls back to the
// untranslated UI rather than failing to find any translator at all. Chinese
// is shipped in Simplified script only, so a Traditional-script system
// (zh_TW, zh_HK) gets "en" rather than the wrong script.
[[nodiscard]] QString language_for_locale(const QLocale& locale);

}  // namespace countdown::app
