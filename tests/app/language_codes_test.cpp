// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#include "language_codes_test.hpp"

#include "language_codes.hpp"

#include <QLocale>
#include <QTest>

using countdown::app::is_supported;
using countdown::app::language_for_locale;
using countdown::app::supported_languages;

void LanguageCodesTest::listsEnglishFirst() {
    const auto languages = supported_languages();
    QVERIFY(!languages.empty());
    QCOMPARE(QString::fromLatin1(languages.front().code), QStringLiteral("en"));
    for (const auto& info : languages) {
        QVERIFY(is_supported(QString::fromLatin1(info.code)));
    }
}

void LanguageCodesTest::isSupported_acceptsShippedCodesOnly() {
    QVERIFY(is_supported(QStringLiteral("ja")));
    QVERIFY(is_supported(QStringLiteral("zh_CN")));
    QVERIFY(!is_supported(QString()));
    QVERIFY(!is_supported(QStringLiteral("zh")));
    QVERIFY(!is_supported(QStringLiteral("zh_TW")));
    QVERIFY(!is_supported(QStringLiteral("sv")));
}

void LanguageCodesTest::languageForLocale_matchesShippedLanguages_data() {
    QTest::addColumn<QString>("locale");
    QTest::addColumn<QString>("expected");

    QTest::newRow("english") << "en_AU" << "en";
    QTest::newRow("french") << "fr_CA" << "fr";
    QTest::newRow("german, Swiss") << "de_CH" << "de";
    QTest::newRow("japanese") << "ja_JP" << "ja";
    QTest::newRow("arabic") << "ar_EG" << "ar";
    QTest::newRow("hebrew") << "he_IL" << "he";
}

void LanguageCodesTest::languageForLocale_matchesShippedLanguages() {
    QFETCH(QString, locale);
    QFETCH(QString, expected);
    QCOMPARE(language_for_locale(QLocale(locale)), expected);
}

void LanguageCodesTest::languageForLocale_chineseNeedsSimplifiedScript_data() {
    QTest::addColumn<QString>("locale");
    QTest::addColumn<QString>("expected");

    QTest::newRow("China") << "zh_CN" << "zh_CN";
    QTest::newRow("Singapore") << "zh_SG" << "zh_CN";
    QTest::newRow("no region") << "zh" << "zh_CN";
    QTest::newRow("Hans script") << "zh_Hans_CN" << "zh_CN";
    QTest::newRow("Taiwan") << "zh_TW" << "en";
    QTest::newRow("Hong Kong") << "zh_HK" << "en";
    QTest::newRow("Hant script") << "zh_Hant" << "en";
}

void LanguageCodesTest::languageForLocale_chineseNeedsSimplifiedScript() {
    QFETCH(QString, locale);
    QFETCH(QString, expected);
    QCOMPARE(language_for_locale(QLocale(locale)), expected);
}

void LanguageCodesTest::languageForLocale_unsupportedFallsBackToEnglish() {
    QCOMPARE(language_for_locale(QLocale(QStringLiteral("sv_SE"))), QStringLiteral("en"));
    QCOMPARE(language_for_locale(QLocale(QStringLiteral("ko_KR"))), QStringLiteral("en"));
    QCOMPARE(language_for_locale(QLocale::c()), QStringLiteral("en"));
}
