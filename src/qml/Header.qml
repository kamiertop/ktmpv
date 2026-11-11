/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml

import org.kde.ki18n
import org.kde.kirigami as Kirigami

import org.kde.haruna
import org.kde.haruna.settings

ToolBar {
    id: root

    required property MpvVideo m_mpv
    required property bool playlistVisible
    readonly property alias m_menuBarLoader: menuBarLoader

    readonly property Main mainWindow: Window.window as Main

    implicitHeight: 44
    leftPadding: 8
    rightPadding: 10
    topPadding: 4
    bottomPadding: 4
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
        }
    }

    position: ToolBar.Header
    // Frameless windows always need their window controls outside fullscreen.
    state: {
        const mainWindow = Window.window as Main
        if (!mainWindow.isFullScreen()) {
            return "visible"
        } else {
            return "hidden"
        }
    }

    onVisibleChanged: {
        const mainWindow = Window.window as Main
        mainWindow.resizeWindow()
    }

    MouseArea {
        property point pressPosition

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: function(mouse) {
            pressPosition = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: function(mouse) {
            if (pressed && Math.hypot(mouse.x - pressPosition.x, mouse.y - pressPosition.y)
                    >= Qt.styleHints.startDragDistance) {
                root.mainWindow.startSystemMove()
            }
        }
        onDoubleClicked: root.mainWindow.toggleMaximized()
    }

    component WindowButton: AbstractButton {
        id: control

        required property string symbol
        implicitWidth: 32
        implicitHeight: 32
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: text

        background: Rectangle {
            radius: 7
            color: Qt.alpha(Kirigami.Theme.textColor,
                            control.down ? 0.20 : control.hovered ? 0.13 : control.checked ? 0.15 : 0)
            Behavior on color { ColorAnimation { duration: 120 } }
            border.width: control.visualFocus ? 1 : 0
            border.color: Kirigami.Theme.highlightColor
        }
        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 13
                radius: 2
                color: "transparent"
                border.width: 1.5
                border.color: Kirigami.Theme.textColor
                visible: control.symbol === "sidebar"

                Rectangle {
                    x: 5
                    y: 1
                    width: 1.5
                    height: parent.height - 2
                    color: Kirigami.Theme.textColor
                }
            }
            // Draw symbolic controls independently of the installed icon theme.
            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 2
                color: Kirigami.Theme.textColor
                visible: control.symbol === "minimize" || control.symbol === "close"
                rotation: control.symbol === "close" ? 45 : 0
            }
            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 2
                color: Kirigami.Theme.textColor
                visible: control.symbol === "close"
                rotation: -45
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: control.symbol === "restore" ? 2 : 0
                anchors.verticalCenterOffset: control.symbol === "restore" ? -2 : 0
                width: 10
                height: 10
                radius: 1
                color: "transparent"
                border.width: 1.5
                border.color: Kirigami.Theme.textColor
                visible: control.symbol === "maximize" || control.symbol === "restore"
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -1
                anchors.verticalCenterOffset: 1
                width: 10
                height: 10
                radius: 1
                color: Kirigami.Theme.backgroundColor
                border.width: 1.5
                border.color: Kirigami.Theme.textColor
                visible: control.symbol === "restore"
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.leftPadding
        anchors.rightMargin: root.rightPadding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        spacing: 6

        WindowButton {
            symbol: "sidebar"
            text: HarunaApp.actions.togglePlaylistAction.text
            checkable: true
            checked: root.playlistVisible
            onClicked: HarunaApp.actions.togglePlaylistAction.trigger()
        }

        HamburgerMenu {
            id: headerMenu
            m_mpv: root.m_mpv
            m_menuBarLoader: menuBarLoader
            position: HamburgerMenu.Position.Header
            visible: !menuBarLoader.visible || menuBarLoader.isShowAnimationRunning
            implicitWidth: 32
            implicitHeight: 32
            hoverEnabled: true
            contentItem: Item {
                Column {
                    anchors.centerIn: parent
                    spacing: 3
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 14
                            height: 1.5
                            radius: 1
                            color: Kirigami.Theme.textColor
                        }
                    }
                }
            }
            background: Rectangle {
                radius: 7
                color: Qt.alpha(Kirigami.Theme.textColor,
                                headerMenu.down || headerMenu.isOpen ? 0.20 : headerMenu.hovered ? 0.13 : 0)
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        MenuBarLoader {
            id: menuBarLoader

            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: Math.max(0, root.width - 188)
            m_mpv: root.m_mpv
            state: !root.mainWindow.isFullScreen() && GeneralSettings.showMenuBar
                   && (showGlobalMenu || root.width >= implicitWidth + 188)
                   ? "visible" : "hidden"
        }

        Item { Layout.fillWidth: true }

        WindowButton {
            symbol: "minimize"
            text: KI18n.i18nc("@action:button", "Minimize")
            onClicked: root.mainWindow.showMinimized()
        }
        WindowButton {
            symbol: root.mainWindow.isMaximized() ? "restore" : "maximize"
            text: root.mainWindow.isMaximized()
                  ? KI18n.i18nc("@action:button", "Restore")
                  : KI18n.i18nc("@action:button", "Maximize")
            onClicked: root.mainWindow.toggleMaximized()
        }
        WindowButton {
            symbol: "close"
            text: KI18n.i18nc("@action:button", "Close")
            onClicked: root.mainWindow.close()
        }
    }


    states: [
        State {
            name: "hidden"
            PropertyChanges {
                root.height: 0
                root.opacity: 0
                root.visible: false
            }
        },
        State {
            name : "visible"
            PropertyChanges {
                root.height: root.implicitHeight
                root.opacity: 1
                root.visible: true
            }
        }
    ]

    transitions: [
        Transition {
            from: "visible"
            to: "hidden"

            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "opacity"
                        duration: Kirigami.Units.veryShortDuration
                        easing.type: Easing.Linear
                    }
                    NumberAnimation {
                        target: root
                        property: "height"
                        duration: Kirigami.Units.veryShortDuration
                        easing.type: Easing.Linear
                    }
                }
                PropertyAction {
                    target: root
                    property: "visible"
                    value: false
                }
            }
        },
        Transition {
            from: "hidden"
            to: "visible"

            SequentialAnimation {
                PropertyAction {
                    target: root
                    property: "visible"
                    value: true
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "height"
                        duration: Kirigami.Units.veryShortDuration
                        easing.type: Easing.Linear
                    }
                    NumberAnimation {
                        target: root
                        property: "opacity"
                        duration: Kirigami.Units.veryShortDuration
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    ]
}
