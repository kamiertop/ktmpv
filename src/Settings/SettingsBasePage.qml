/*
 * SPDX-FileCopyrightText: 2021 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami
import org.kde.kirigami.layouts as KirigamiLayouts

Kirigami.ScrollablePage {
    id: root

    signal save()

    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    KirigamiLayouts.ColumnView.fillWidth: true
    padding: 22
    background: Rectangle { color: Kirigami.Theme.backgroundColor }
    header: Label {
        visible: root.title.length > 0
        text: root.title
        leftPadding: root.leftPadding
        rightPadding: root.rightPadding
        topPadding: 20
        bottomPadding: 10
        font.pixelSize: 23
        font.weight: Font.DemiBold
        color: Kirigami.Theme.textColor
    }

    Component.onDestruction: save()
}
