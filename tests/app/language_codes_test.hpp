// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>

// countdown::app::language_for_locale and is_supported: which system locales
// get a translation and which fall back to the untranslated UI.
class LanguageCodesTest : public QObject {
    Q_OBJECT

private slots:
    void listsEnglishFirst();
    void isSupported_acceptsShippedCodesOnly();
    void languageForLocale_matchesShippedLanguages_data();
    void languageForLocale_matchesShippedLanguages();
    void languageForLocale_chineseNeedsSimplifiedScript_data();
    void languageForLocale_chineseNeedsSimplifiedScript();
    void languageForLocale_unsupportedFallsBackToEnglish();
};
