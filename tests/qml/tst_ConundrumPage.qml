// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Countdown

TestCase {
    id: testCase
    name: "ConundrumPage"

    Component { id: pageComponent; ConundrumPage {} }

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

    function test_solveFindsTheAnagram() {
        const page = createTemporaryObject(pageComponent, testCase)
        verify(page !== null)

        // "countdown"'s own letters are a unique full anagram among the
        // fallback words, so this always resolves to exactly that word.
        const word = "countdown"
        for (let i = 0; i < word.length; ++i) {
            page.addLetter(word.charAt(i).toUpperCase())
        }
        compare(page.letters.length, 9)

        page.recalc()
        verify(page.result !== null)
        compare(page.result.found, true)
        compare(page.result.answers, ["countdown"])
    }

    function test_notFound() {
        const page = createTemporaryObject(pageComponent, testCase)
        for (const ch of "XYZXYZXYZ") {
            page.addLetter(ch)
        }
        page.recalc()

        verify(page.result !== null)
        compare(page.result.found, false)
        compare(page.result.answers.length, 0)
    }

    function test_clearAllResetsState() {
        const page = createTemporaryObject(pageComponent, testCase)
        page.addLetter("A")
        page.clearAll()

        compare(page.letters.length, 0)
        compare(page.result, null)
    }

    function test_randomConundrumProducesAPlayableRound() {
        const page = createTemporaryObject(pageComponent, testCase)
        page.randomConundrum()

        compare(page.letters.length, 9)
        verify(page.result !== null)
        // A shuffled fallback word is always a full anagram of itself.
        compare(page.result.found, true)
    }
}
