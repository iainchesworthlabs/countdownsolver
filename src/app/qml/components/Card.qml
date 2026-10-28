// SPDX-FileCopyrightText: 2026 Iain Chesworth
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// A panel/card surface. Put a ColumnLayout (anchors.fill + margins) inside.
Rectangle {
    property int cornerRadius: Theme.radiusCard
    color: Theme.panel
    border.color: Theme.border
    border.width: 1
    radius: cornerRadius
}
