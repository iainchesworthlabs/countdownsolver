// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>

// A Letters and a Conundrum round in each language that has its own alphabet and word list:
// the rack has the language's size and only its letters, the solver answers from its own
// dictionary, and the Conundrum word can be solved again. The word lists are starter lists
// (docs/how-to-play.md), so these tests check the wiring and not how many words they hold.
class LanguageRoundTest : public QObject {
    Q_OBJECT

private slots:
    void lettersRound_data();
    void lettersRound();

    void conundrumRound_data();
    void conundrumRound();

    void rackLettersBelongToTheLanguage_data();
    void rackLettersBelongToTheLanguage();
};
