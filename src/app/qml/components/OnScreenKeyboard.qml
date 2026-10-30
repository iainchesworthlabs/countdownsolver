// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Shared on-screen QWERTY-ish keyboard for LettersPage/ConundrumPage. Purely
// a view - it owns no rack/letters state and does no physical-key handling
// itself (the embedding page owns `letters` and Keys.onPressed directly, the
// same way NumbersPage owns its own state - that keeps this component stateless
// so it's safe to recreate per form-factor layout without losing anything the
// user typed).
Item {
    id: root
    signal keyPressed(string ch)

    // Real regional keyboard layouts as a low-cost polish touch - French's
    // alphabet folds every accent away so AZERTY needs no extra keys, but
    // German's Ä/Ö/Ü and Spanish's Ñ are distinct alphabet slots that must
    // be reachable, so those languages get an extra key/row for them.
    // Physical keyboard input stays ASCII-only for every language (handled
    // by the embedding page) - the on-screen keyboard is the complete/
    // authoritative input method, not just a QWERTY convenience.
    // Arabic/Hebrew/Yiddish rows are authored in logical (reading-order)
    // sequence, same as every LTR row above - the app's global
    // LayoutMirroring (Main.qml) already flips each row's RowLayout visually
    // for RTL, so no manual reversal is needed here, same mechanism as every
    // other mirrored control in the app. These aren't a physical-keyboard-
    // accurate scancode layout (no single standard exists across regions
    // the way QWERTY/AZERTY/QWERTZ do) - just the full letter set split into
    // rows for on-screen use, same "original design, no reference to copy"
    // caveat as these three languages' rack/alphabet rules generally.
    readonly property var keyRowsByLanguage: ({
        "fr": ["AZERTYUIOP", "QSDFGHJKLM", "WXCVBN"],
        "de": ["QWERTZUIOP", "ASDFGHJKL", "YXCVBNM", "ÄÖÜ"],
        "es": ["QWERTYUIOP", "ASDFGHJKLÑ", "ZXCVBNM"],
        "ar": ["ابتثجحخدذر", "زسشصضطظعغف", "قكلمنهوية"],
        "he": ["אבגדהוזח", "טיכלמנסע", "פצקרשת"],
        // No dedicated row for Yiddish's three extra digraph letters
        // (tsvey-vovn/vov-yod/tsvey-yudn - see fold_yiddish() in
        // alphabet.cpp): unlike German's Ä/Ö/Ü (a single distinct alphabet
        // slot each, unreachable any other way), every Yiddish digraph is
        // just two base letters already on this keyboard (vav+vav,
        // vav+yod, yod+yod) pressed in sequence - same as typing "sh" in
        // English takes two keystrokes. Reuses the Hebrew rows as-is.
        "yi": ["אבגדהוזח", "טיכלמנסע", "פצקרשת"],
    })
    // Guarded against a null languageManager for the same reason as
    // Theme.qml's `sans` - falls back to QWERTY until the next re-evaluation.
    readonly property var keyRows: (languageManager && keyRowsByLanguage[languageManager.currentLanguage])
                                    || ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    readonly property real padding: Metrics.pick(Metrics.qwertyKey.pad, 18)
    readonly property real keyGap: Metrics.pick(Metrics.qwertyKey.gap, 5)
    readonly property real keyWidthMax: Metrics.pick(Metrics.qwertyKey.maxWidth, 36)
    readonly property int columns: keyRows.reduce(function (most, row) { return Math.max(most, row.length) }, 1)
    // Every key is as wide as the longest row allows, so the rows line up and
    // none runs past the card. Read from the card's width, not the keys', so the
    // implicit width below stays the width the keys would like.
    readonly property real keyWidth: Math.max(1, Math.min(keyWidthMax,
        Math.floor((width - 2 * padding - (columns - 1) * keyGap) / columns)))

    implicitWidth: columns * keyWidthMax + (columns - 1) * keyGap + 2 * padding
    implicitHeight: kb.implicitHeight + 2 * padding

    Card {
        anchors.fill: parent
        cornerRadius: Metrics.compactIndex < 0 ? Theme.radiusCard : Metrics.cardRadius.value[Metrics.compactIndex]
        ColumnLayout {
            id: kb
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 6
            Repeater {
                model: root.keyRows
                delegate: RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: root.keyGap
                    property string rowStr: modelData
                    Repeater {
                        model: rowStr.length
                        delegate: PadButton {
                            objectName: "key"
                            implicitWidth: root.keyWidth
                            implicitHeight: Metrics.compactIndex < 0 ? 44 : Metrics.touchSize(Metrics.qwertyKey.size[Metrics.compactIndex])
                            mono: false
                            fontSize: Metrics.compactIndex < 0 ? 15 : Metrics.qwertyKey.font[Metrics.compactIndex]
                            text: rowStr.charAt(index)
                            onClicked: root.keyPressed(rowStr.charAt(index))
                        }
                    }
                }
            }
        }
    }
}
