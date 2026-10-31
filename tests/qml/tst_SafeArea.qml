// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtTest
import Countdown

// The screen's unsafe areas (status bar, notch, home indicator) are reported
// by Qt as SafeArea.margins, which are all zero on desktop, so these tests set
// the insets by hand the way a phone would report them.
TestCase {
    id: testCase
    name: "SafeArea"
    visible: true
    width: 600
    height: 300

    Component { id: mainComponent; Main {} }
    Component {
        id: tabBarComponent
        BottomTabBar {
            tabs: [["Numbers", "12"], ["Letters", "Aa"], ["Conundrum", "?"], ["Settings", "≡"]]
        }
    }

    function cleanup() {
        Metrics.formFactor = FormFactor.desktop
    }

    function test_tabBarGrowsBelowItsTabsAndKeepsThemClearOfTheInsets() {
        Metrics.formFactor = FormFactor.phonePortrait
        const plain = createTemporaryObject(tabBarComponent, testCase, { width: 402 })
        verify(plain !== null)
        const base = plain.implicitHeight

        const bar = createTemporaryObject(tabBarComponent, testCase,
                                          { width: 402, safeLeft: 20, safeRight: 24, safeBottom: 34 })
        verify(bar !== null)
        compare(bar.implicitHeight, base + 34)
        bar.height = bar.implicitHeight

        let tabs = 0
        for (let i = 0; i < bar.children.length; ++i) {
            const row = bar.children[i]
            if (row.children === undefined) continue
            for (let j = 0; j < row.children.length; ++j) {
                const tab = row.children[j]
                if (tab.glyph === undefined) continue
                const at = tab.mapToItem(bar, 0, 0)
                verify(at.x >= 20, "tab " + tab.text + " starts inside the left inset")
                verify(at.x + tab.width <= bar.width - 24, "tab " + tab.text + " ends inside the right inset")
                verify(at.y + tab.height <= bar.height - 34, "tab " + tab.text + " reaches the home indicator")
                ++tabs
            }
        }
        compare(tabs, 4)

        bar.destroy()
        plain.destroy()
        wait(10)
    }

    function test_shellContentStaysInsideTheInsets() {
        const win = mainComponent.createObject(null)
        verify(win !== null)
        win.safeTop = 60
        win.safeBottom = 34
        win.safeLeft = 20
        win.safeRight = 24
        wait(50)

        const content = findChild(win.contentItem, "shellContent")
        verify(content !== null)
        // The layout settles after the insets change, which takes longer on a
        // busy machine than any fixed wait, so poll for it.
        tryVerify(function() { return content.mapToItem(win.contentItem, 0, 0).y >= 60 },
                  5000, "content starts under the status bar")
        tryVerify(function() { return content.mapToItem(win.contentItem, 0, 0).x >= 20 },
                  5000, "content starts under the left inset")
        tryVerify(function() {
            return content.mapToItem(win.contentItem, 0, 0).x + content.width <= win.width - 24
        }, 5000, "content runs under the right inset")
        tryVerify(function() {
            return content.mapToItem(win.contentItem, 0, 0).y + content.height <= win.height - 34
        }, 5000, "content runs under the home indicator")

        // And with no insets it fills the window, as it always has.
        win.safeTop = 0
        win.safeBottom = 0
        win.safeLeft = 0
        win.safeRight = 0
        tryVerify(function() {
            const whole = content.mapToItem(win.contentItem, 0, 0)
            return whole.x === 0 && whole.y === 0
                && content.width === win.width && content.height === win.height
        }, 5000, "content fills the window once the insets are gone")

        win.destroy()
        wait(50)
    }
}
