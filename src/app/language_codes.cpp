// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#include "language_codes.hpp"

#include <array>

namespace countdown::app {
namespace {

constexpr std::array<LanguageInfo, 9> kLanguages{{
    {"en", "English"},
    {"fr", "Français"},
    {"de", "Deutsch"},
    {"es", "Español"},
    {"ar", "العربية"},
    {"he", "עברית"},
    {"yi", "יידיש"},
    {"ja", "日本語"},
    {"zh_CN", "简体中文"},
}};

}  // namespace

std::span<const LanguageInfo> supported_languages() noexcept {
    return kLanguages;
}

bool is_supported(const QString& code) {
    for (const LanguageInfo& info : kLanguages) {
        if (code == QLatin1String(info.code)) {
            return true;
        }
    }
    return false;
}

QString language_for_locale(const QLocale& locale) {
    if (locale.language() == QLocale::Chinese) {
        return locale.script() == QLocale::SimplifiedChineseScript ? QStringLiteral("zh_CN")
                                                                   : QStringLiteral("en");
    }
    const QString name = QLocale::languageToCode(locale.language());
    return is_supported(name) ? name : QStringLiteral("en");
}

}  // namespace countdown::app
