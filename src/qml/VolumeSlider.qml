/*
 * SPDX-FileCopyrightText: 2023 George Florea Bănuș <georgefb899@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import org.kde.haruna
import org.kde.haruna.settings

Basic.Slider {
    id: root

    required property MpvItem m_mpv
    property alias label: volumeLabel

    from: 0
    to: root.m_mpv.volumeMax
    value: root.m_mpv.volume
    implicitWidth: 80
    implicitHeight: 30
    wheelEnabled: true
    hoverEnabled: true
    stepSize: AudioSettings.volumeStep
    leftPadding: 5
    rightPadding: 5
    onMoved: root.m_mpv.volume = Math.round(value)

    background: Rectangle {
        x: root.leftPadding
        y: (root.height - height) / 2
        width: root.availableWidth
        height: 3
        radius: height / 2
        color: "#35ffffff"
        Rectangle {
            x: root.mirrored ? parent.width - width : 0
            width: root.position * parent.width
            height: parent.height
            radius: height / 2
            color: "#e4e4e7"
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * root.availableWidth - width / 2
        y: (root.height - height) / 2
        width: 10
        height: 10
        radius: 5
        color: "#ffffff"
        visible: root.hovered || root.pressed || root.visualFocus
    }
    Label {
        id: volumeLabel
        visible: false
        text: Math.round(root.value)
    }
    ToolTip.visible: hovered || pressed
    ToolTip.text: Math.round(value) + "%"
    ToolTip.delay: 500
}
