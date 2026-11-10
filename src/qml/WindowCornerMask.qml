/*
 * SPDX-FileCopyrightText: 2026 Haruna contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import Qt5Compat.GraphicalEffects

OpacityMask {
    id: root

    property real cornerRadius: 0
    property bool roundTop: true
    property bool roundBottom: false

    maskSource: Rectangle {
        width: root.width
        height: root.height
        topLeftRadius: root.roundTop ? root.cornerRadius : 0
        topRightRadius: root.roundTop ? root.cornerRadius : 0
        bottomLeftRadius: root.roundBottom ? root.cornerRadius : 0
        bottomRightRadius: root.roundBottom ? root.cornerRadius : 0
    }
}
