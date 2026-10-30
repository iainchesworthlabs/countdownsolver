// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Countdown

TestCase {
    id: testCase
    name: "LettersPage"

    Component { id: pageComponent; LettersPage {} }
    Component { id: keyboardComponent; OnScreenKeyboard {} }

    function cleanup() {
        Metrics.formFactor = FormFactor.desktop
    }

    function keysOf(item, out) {
        out = out || []
        for (let i = 0; i < item.children.length; ++i) {
            if (item.children[i].objectName === "key") out.push(item.children[i])
            keysOf(item.children[i], out)
        }
        return out
    }

    // Widths are what the keyboard card gets: the window less the page's side
    // margins. The longest row is ten keys, which at the widest key size
    // wants far more than a phone or a small tablet has.
    function test_keysStayInsideTheKeyboard_data() {
        return [
            { tag: "desktop",        form: FormFactor.desktop,        w: 456 },
            { tag: "iPhone 17",      form: FormFactor.phonePortrait,  w: 366 },
            { tag: "iPhone SE",      form: FormFactor.phonePortrait,  w: 339 },
            { tag: "smallest phone", form: FormFactor.phonePortrait,  w: 284 },
            { tag: "phone landscape", form: FormFactor.phoneLandscape, w: 420 },
            { tag: "iPad mini",      form: FormFactor.tabletPortrait, w: 692 }
        ]
    }

    function test_keysStayInsideTheKeyboard(data) {
        Metrics.formFactor = data.form
        const keyboard = createTemporaryObject(keyboardComponent, testCase, { width: data.w, height: 200 })
        verify(keyboard !== null)

        const keys = keysOf(keyboard)
        verify(keys.length >= 20, "found " + keys.length + " keys")
        for (const key of keys) {
            const at = key.mapToItem(keyboard, 0, 0)
            verify(at.x >= 0, key.text + " starts left of the keyboard")
            verify(at.x + key.width <= keyboard.width, key.text + " runs past the right edge")
        }

        // A narrower keyboard shrinks every key alike, so the rows still line up.
        verify(keys.every(function (key) { return key.width === keys[0].width }), "keys differ in width")

        // Gone before cleanup() puts the metrics back.
        keyboard.destroy()
        wait(10)
    }

    function cleanup() {
        Metrics.formFactor = FormFactor.desktop
    }

    // The page area left under the header, the Input/Results toggle and the
    // tab bar is short on a phone. Solve must stay inside it, with the cards
    // scrolling above it, rather than rolling off the bottom.
    function test_solveStaysInViewOnShortPortraitWindows_data() {
        return [
            { tag: "iPhone 17",      form: FormFactor.phonePortrait,  w: 402, h: 560 },
            { tag: "iPhone SE",      form: FormFactor.phonePortrait,  w: 375, h: 440 },
            { tag: "smallest phone", form: FormFactor.phonePortrait,  w: 320, h: 330 },
            { tag: "iPad mini",      form: FormFactor.tabletPortrait, w: 744, h: 700 },
            { tag: "short tablet",   form: FormFactor.tabletPortrait, w: 744, h: 400 }
        ]
    }

    function test_solveStaysInViewOnShortPortraitWindows(data) {
        Metrics.formFactor = data.form
        const page = createTemporaryObject(pageComponent, testCase, { width: data.w, height: data.h })
        verify(page !== null)

        const solve = findChild(page, "solveButton")
        verify(solve !== null)
        const topLeft = solve.mapToItem(page, 0, 0)
        verify(topLeft.x >= 0, "Solve starts left of the page")
        verify(topLeft.y >= 0, "Solve starts above the page")
        verify(topLeft.x + solve.width <= page.width, "Solve runs past the right edge")
        verify(topLeft.y + solve.height <= page.height, "Solve runs past the bottom edge")

        // Gone before cleanup() puts the metrics back, which would otherwise
        // re-evaluate this layout's per-form-factor bindings with no form factor.
        page.destroy()
        wait(10)
    }

    // Every letter in `word` occurs in `rack` at least as often - i.e. `word`
    // is genuinely spellable from `rack`'s letters. Used to check results
    // against the real (large) bundled dictionary without depending on its
    // exact contents.
    function canSpell(rack, word) {
        const counts = {}
        for (const ch of rack.toLowerCase()) counts[ch] = (counts[ch] || 0) + 1
        for (const ch of word.toLowerCase()) {
            if (!counts[ch]) return false
            counts[ch] -= 1
        }
        return true
    }

    function test_solveFindsRichRackWords() {
        const page = createTemporaryObject(pageComponent, testCase)
        verify(page !== null)

        // "creations" is a letter-rich 9-letter rack (the LettersPage cap);
        // exact word content isn't asserted (the dictionary can change
        // independently of this test) - every structural invariant of the
        // response is instead.
        const word = "creations"
        for (let i = 0; i < word.length; ++i) {
            page.addLetter(word.charAt(i).toUpperCase())
        }
        compare(page.letters.length, word.length)

        page.recalc()
        verify(page.result !== null)
        verify(page.result.total > 0)
        verify(page.result.longest.length > 0)
        for (const w of page.result.longest) {
            compare(w.length, page.result.maxLen)
            verify(canSpell(word, w))
        }
        for (const group of page.result.groups) {
            for (const w of group.words) {
                compare(w.length, group.len)
                verify(canSpell(word, w))
            }
        }
    }

    function test_noMatches() {
        const page = createTemporaryObject(pageComponent, testCase)
        for (const ch of "XYZXYZ") {
            page.addLetter(ch)
        }
        page.recalc()

        verify(page.result !== null)
        compare(page.result.total, 0)
    }

    function test_backspaceRemovesLastLetter() {
        const page = createTemporaryObject(pageComponent, testCase)
        page.addLetter("A")
        page.addLetter("B")
        page.backspace()

        compare(page.letters.length, 1)
        compare(page.letters[0], "A")
    }

    function test_clearAllResetsState() {
        const page = createTemporaryObject(pageComponent, testCase)
        page.addLetter("A")
        page.clearAll()

        compare(page.letters.length, 0)
        compare(page.result, null)
    }

    function test_randomRackProducesAPlayableRound() {
        const page = createTemporaryObject(pageComponent, testCase)
        page.randomRack()

        // randomRack() now draws from a weighted letter-tile pool
        // independent of the dictionary (matching the real show), so a
        // given draw isn't guaranteed to spell any word at all - only that
        // recalc() ran and produced a well-formed (if possibly empty) result.
        compare(page.letters.length, 9)
        verify(page.result !== null)
        verify(page.result.total >= 0)
        for (const w of page.result.longest) {
            verify(canSpell(page.letters.join(""), w))
        }
    }
}
