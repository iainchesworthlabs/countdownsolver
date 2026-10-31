// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#include "solver_languages_test.hpp"

#include "solver.hpp"

#include <QChar>
#include <QString>
#include <QStringList>
#include <QTest>
#include <QVariant>
#include <QVariantMap>

#include <memory>

namespace {

using countdown::app::Solver;

constexpr int kRoundsPerLanguage = 40;

// Each language with the size of its rack and the script its letters are written in.
struct LanguageCase {
    const char* code;
    int rackSize;
    QChar::Script script;
};

constexpr LanguageCase kCases[] = {
    {"fr", 10, QChar::Script_Latin}, {"de", 9, QChar::Script_Latin},
    {"es", 9, QChar::Script_Latin},  {"ar", 9, QChar::Script_Arabic},
    {"he", 9, QChar::Script_Hebrew}, {"yi", 9, QChar::Script_Hebrew},
};

void addLanguages() {
    QTest::addColumn<QString>("code");
    QTest::addColumn<int>("rackSize");
    QTest::addColumn<int>("script");
    for (const LanguageCase& c : kCases) {
        QTest::newRow(c.code) << QString::fromLatin1(c.code) << c.rackSize
                              << static_cast<int>(c.script);
    }
}

// One Solver per language, built the way main.cpp does at start-up (a language first, then the
// dictionaries), so the shared English fixture of the other test classes is left alone.
[[nodiscard]] std::unique_ptr<Solver> solverFor(const QString& code) {
    auto solver = std::make_unique<Solver>(nullptr, Solver::DictionaryLoad::kDeferred);
    solver->setLanguageCode(code);
    solver->loadDictionaries();
    return solver;
}

}  // namespace

void LanguageRoundTest::lettersRound_data() {
    addLanguages();
}

void LanguageRoundTest::lettersRound() {
    QFETCH(QString, code);
    QFETCH(int, rackSize);
    const auto solver = solverFor(code);

    QVERIFY(solver->dictionaryWordCount() > 0);
    QCOMPARE(solver->rackSize(), rackSize);

    for (int round = 0; round < kRoundsPerLanguage; ++round) {
        const QString rack = solver->randomRack();
        QCOMPARE(rack.size(), rackSize);

        const QVariantMap result = solver->solveLetters(rack, 2, 0);
        QVERIFY2(result.contains("total"), qPrintable(rack));
        if (result.value("total").toInt() == 0) {
            continue;
        }

        // A word is never longer than the rack. Counting the bytes of the UTF-8 text instead
        // of letters gives a length of up to twice that for é, ب, ש and the like.
        const int maxLen = result.value("maxLen").toInt();
        QVERIFY2(maxLen >= 2 && maxLen <= rackSize, qPrintable(rack));

        // Groups run from the longest words down, one group for each length, and the first
        // group holds the longest words.
        const QVariantList groups = result.value("groups").toList();
        QVERIFY(!groups.isEmpty());
        int previous = rackSize + 1;
        int counted = 0;
        for (const QVariant& entry : groups) {
            const QVariantMap group = entry.toMap();
            const int len = group.value("len").toInt();
            QVERIFY2(len < previous, qPrintable(rack));
            previous = len;
            counted += group.value("count").toInt();
        }
        QCOMPARE(groups.first().toMap().value("len").toInt(), maxLen);
        QCOMPARE(counted, result.value("total").toInt());

        const QStringList longest = result.value("longest").toStringList();
        QCOMPARE(longest, groups.first().toMap().value("words").toStringList());
    }
}

void LanguageRoundTest::conundrumRound_data() {
    addLanguages();
}

void LanguageRoundTest::conundrumRound() {
    QFETCH(QString, code);
    QFETCH(int, rackSize);
    const auto solver = solverFor(code);

    for (int round = 0; round < kRoundsPerLanguage; ++round) {
        const QString letters = solver->randomConundrum();
        QVERIFY2(!letters.isEmpty(), "the dictionary holds no word of the rack's length");
        QCOMPARE(letters.size(), rackSize);

        // A Conundrum is a shuffled dictionary word, so solving it finds at least that word.
        const QVariantMap result = solver->solveConundrum(letters);
        QVERIFY2(result.value("found").toBool(), qPrintable(letters));
        QVERIFY(!result.value("answers").toStringList().isEmpty());
    }
}

void LanguageRoundTest::rackLettersBelongToTheLanguage_data() {
    addLanguages();
}

void LanguageRoundTest::rackLettersBelongToTheLanguage() {
    QFETCH(QString, code);
    QFETCH(int, script);
    const auto solver = solverFor(code);

    for (int round = 0; round < kRoundsPerLanguage; ++round) {
        for (const QString& rack : {solver->randomRack(), solver->randomConundrum()}) {
            for (const QChar ch : rack) {
                QVERIFY2(ch.isLetter() && ch.script() == static_cast<QChar::Script>(script),
                         qPrintable(rack));
            }
        }
    }
}
