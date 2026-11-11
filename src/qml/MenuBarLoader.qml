/*
 * SPDX-FileCopyrightText: 2023 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic as Basic
import Qt.labs.platform as Platform

import org.kde.kirigami as Kirigami

import org.kde.haruna
import org.kde.haruna.utilities
import org.kde.haruna.settings

Loader {
    id: root

    required property MpvVideo m_mpv

    property bool isShowAnimationRunning: false
    property bool showGlobalMenu: SystemUtils.platformName() !== "windows"
                                    && Kirigami.Settings.hasPlatformMenuBar
                                    && !Kirigami.Settings.isMobile

    clip: true
    asynchronous: !GeneralSettings.showMenuBar
    sourceComponent: showGlobalMenu ? globalMenuBarComponent : menuBarComponent

    Component {
        id: menuBarComponent

        Basic.MenuBar {
            hoverEnabled: true
            padding: 0
            spacing: 2
            background: Item {}

            delegate: Basic.MenuBarItem {
                id: menuItem

                implicitHeight: 32
                leftPadding: 9
                rightPadding: 9
                hoverEnabled: true

                palette.buttonText: Kirigami.Theme.textColor

                background: Rectangle {
                    radius: 7
                    color: Qt.alpha(Kirigami.Theme.textColor,
                                    menuItem.down || menuItem.menu?.opened ? 0.20
                                    : menuItem.hovered || menuItem.highlighted ? 0.13 : 0)
                    border.width: menuItem.visualFocus ? 1 : 0
                    border.color: Kirigami.Theme.highlightColor
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            FileMenu {}
            ViewMenu {}
            PlaybackMenu {}
            VideoMenu {}
            SubtitlesMenu {
                m_mpv: root.m_mpv
            }
            AudioMenu {
                m_mpv: root.m_mpv
            }
            SettingsMenu {}
            HelpMenu {}
        }
    }

    Component {
        id: globalMenuBarComponent

        Platform.MenuBar {
            GlobalFileMenu {}
            GlobalViewMenu {}
            GlobalPlaybackMenu {}
            GlobalVideoMenu {}
            GlobalSubtitlesMenu {
                m_mpv: root.m_mpv
            }
            GlobalAudioMenu {
                m_mpv: root.m_mpv
            }
            GlobalSettingsMenu {}
            GlobalHelpMenu {}
        }
    }

    states: [
        State {
            name: "hidden"
            PropertyChanges {
                root.height: 0
                root.visible: false
            }
        },
        State {
            name : "visible"
            PropertyChanges {
                root.height: root.implicitHeight
                root.visible: true
            }
        }
    ]

    transitions: [
        Transition {
            from: "visible"
            to: "hidden"

            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "height"
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.Linear
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
                    property: "isShowAnimationRunning"
                    value: true
                }
                PropertyAction {
                    target: root
                    property: "visible"
                    value: true
                }
                NumberAnimation {
                    target: root
                    property: "height"
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.Linear
                }
                PropertyAction {
                    target: root
                    property: "isShowAnimationRunning"
                    value: false
                }
            }
        }
    ]
}
