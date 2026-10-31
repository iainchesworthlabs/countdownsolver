// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Countdown

TestCase {
    id: testCase
    name: "SettingsPage"

    Component { id: pageComponent; SettingsPage {} }

    function cleanup() {
        Metrics.formFactor = FormFactor.desktop
    }

    function textsOf(item, out) {
        out = out || []
        for (let i = 0; i < item.children.length; ++i) {
            const child = item.children[i]
            if (child.text !== undefined && child.contentWidth !== undefined && child.text !== "")
                out.push(child)
            textsOf(child, out)
        }
        return out
    }

    function isInside(item, ancestor) {
        for (let at = item; at; at = at.parent) {
            if (at === ancestor) return true
        }
        return false
    }

    function overlap(a, b) {
        return a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height
    }

    function rectIn(page, item) {
        const at = item.mapToItem(page, 0, 0)
        return { x: at.x, y: at.y, width: item.width, height: item.height }
    }

    function formFactors() {
        return [
            { tag: "iPhone SE",       form: FormFactor.phonePortrait,  w: 375, h: 500 },
            { tag: "smallest phone",  form: FormFactor.phonePortrait,  w: 320, h: 400 },
            { tag: "phone landscape", form: FormFactor.phoneLandscape, w: 844, h: 300 },
            { tag: "iPad mini",       form: FormFactor.tabletPortrait, w: 744, h: 700 }
        ]
    }

    // The setting names and their descriptions wrap onto more lines instead of
    // running past the end of their card.
    function test_textFitsItsBox_data() { return formFactors() }

    function test_textFitsItsBox(data) {
        Metrics.formFactor = data.form
        const page = createTemporaryObject(pageComponent, testCase, { width: data.w, height: data.h })
        verify(page !== null)
        wait(50)
        const texts = textsOf(page)
        verify(texts.length > 10, "found " + texts.length + " texts")
        for (const text of texts) {
            verify(text.contentWidth <= text.width + 1,
                   "\"" + text.text + "\" is " + text.contentWidth + " wide in a box " + text.width + " wide")
        }
        page.destroy()
        wait(10)
    }

    // Where two settings sit in a row (label left, control right), the control
    // does not cover the label.
    function test_controlsDoNotCoverTheirLabels_data() { return formFactors() }

    function test_controlsDoNotCoverTheirLabels(data) {
        Metrics.formFactor = data.form
        const page = createTemporaryObject(pageComponent, testCase, { width: data.w, height: data.h })
        verify(page !== null)
        for (const name of ["themeSeg", "langCombo", "dictSeg", "minLenSeg"]) {
            const control = findChild(page, name)
            verify(control !== null, name)
            const box = rectIn(page, control)
            for (const text of textsOf(page)) {
                if (isInside(text, control)) continue
                const at = rectIn(page, text)
                // What the text paints, which is wider than its box when it overflows.
                at.width = text.contentWidth
                verify(!overlap(box, at), name + " covers \"" + text.text + "\"")
            }
        }
        page.destroy()
        wait(10)
    }

    function test_instantiatesAndBindsToSolver() {
        const page = createTemporaryObject(pageComponent, testCase)
        verify(page !== null)

        // These bindings call solver.fullDictionaryAvailable()/versionDetails()
        // directly, so successfully finding them confirms the QML<->Solver
        // wiring works end to end, not just that Solver's C++ API is correct.
        const dictSeg = findChild(page, "dictSeg")
        verify(dictSeg !== null)
        compare(dictSeg.enabled, solver.fullDictionaryAvailable())

        const themeSeg = findChild(page, "themeSeg")
        verify(themeSeg !== null)
        compare(themeSeg.options.length, 3)

        const about = findChild(page, "aboutText")
        verify(about !== null)
        verify(about.versionLines.length > 0)
        verify(about.versionLines[0].length > 0)
    }

    // The link goes to the organisation's repository, not the old owner's name.
    function test_repositoryLinkPointsAtTheOrganisationRepository() {
        const page = createTemporaryObject(pageComponent, testCase)
        verify(page !== null)
        verify(findChild(page, "repoLink") !== null)
        compare(page.repositoryUrl.toString(), "https://github.com/iainchesworthlabs/countdownsolver")
    }

    function test_licensesLinkOpensDialog() {
        const page = createTemporaryObject(pageComponent, testCase)
        verify(page !== null)

        const link = findChild(page, "licensesLink")
        verify(link !== null)

        const dialog = page.licensesDialog
        verify(dialog !== null)
        compare(dialog.visible, false)

        // Entries pull solver.qtVersion() live, so a populated version string
        // confirms the QML<->Solver wiring works, not just that the array
        // literal itself is non-empty.
        verify(dialog.entries.length > 0)
        compare(dialog.entries[0].name, "Qt 6")
        verify(dialog.entries[0].version.length > 0)

        dialog.open()
        compare(dialog.visible, true)
        dialog.close()
    }
}
