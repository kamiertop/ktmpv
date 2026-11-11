/*
 * SPDX-FileCopyrightText: 2024 George Florea Bănuș <georgefb899@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import org.kde.ki18n
import org.kde.haruna
import org.kde.haruna.playlist

Item {
    id: root
    objectName: "PlaybackControls"

    required property MpvVideo m_mpv
    required property PlaylistsManager playlistsManager
    required property MenuBarLoader m_menuBarLoader
    required property Header m_header

    property alias progressBar: progressBar
    readonly property bool isFloating: true
    readonly property Main mainWindow: Window.window as Main
    readonly property bool hasPlayback: m_mpv.playbackState === MpvItem.PlaybackState.Playing
                                        || m_mpv.playbackState === MpvItem.PlaybackState.Paused
    readonly property bool controlsVisible: footerHover.hovered || progressBar.interacting
                                             || volumeSlider.pressed || hamburgerMenu.isOpen

    visible: hasPlayback && width >= 240
    implicitHeight: 64

    // Keep this hover target present even while the controls themselves are hidden.
    HoverHandler { id: footerHover }

    component PlayerIcon: Canvas {
        required property string symbol
        width: 24
        height: 24
        onSymbolChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = "#ffffff"
            ctx.fillStyle = "#ffffff"
            ctx.lineWidth = 1.7
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.shadowColor = "#a0000000"
            ctx.shadowBlur = 3
            ctx.shadowOffsetY = 1
            ctx.beginPath()
            if (symbol === "play") {
                ctx.moveTo(7, 4); ctx.lineTo(20, 12); ctx.lineTo(7, 20); ctx.closePath()
            } else if (symbol === "pause") {
                ctx.rect(6, 5, 3, 14); ctx.rect(15, 5, 3, 14)
            } else if (symbol === "previous") {
                ctx.moveTo(18, 5); ctx.lineTo(8, 12); ctx.lineTo(18, 19); ctx.closePath()
                ctx.moveTo(5, 5); ctx.lineTo(5, 19)
            } else if (symbol === "next") {
                ctx.moveTo(6, 5); ctx.lineTo(16, 12); ctx.lineTo(6, 19); ctx.closePath()
                ctx.moveTo(19, 5); ctx.lineTo(19, 19)
            } else if (symbol === "volume" || symbol === "muted") {
                ctx.moveTo(3, 9); ctx.lineTo(7, 9); ctx.lineTo(12, 5)
                ctx.lineTo(12, 19); ctx.lineTo(7, 15); ctx.lineTo(3, 15); ctx.closePath()
                if (symbol === "muted") {
                    ctx.moveTo(16, 9); ctx.lineTo(22, 15)
                    ctx.moveTo(22, 9); ctx.lineTo(16, 15)
                } else {
                    ctx.moveTo(16, 8); ctx.quadraticCurveTo(20, 12, 16, 16)
                    ctx.moveTo(19, 5); ctx.quadraticCurveTo(25, 12, 19, 19)
                }
            } else if (symbol === "maximize") {
                ctx.rect(5, 5, 14, 14)
            } else if (symbol === "restore") {
                ctx.rect(4, 8, 12, 12)
                ctx.moveTo(8, 5); ctx.lineTo(8, 4); ctx.lineTo(20, 4)
                ctx.lineTo(20, 16); ctx.lineTo(19, 16)
            } else if (symbol === "fullscreen" || symbol === "leaveFullscreen") {
                const outer = symbol === "fullscreen"
                const a = outer ? 3 : 8
                const b = outer ? 21 : 16
                const c = outer ? 8 : 3
                const d = outer ? 16 : 21
                ctx.moveTo(c, a); ctx.lineTo(a, a); ctx.lineTo(a, c)
                ctx.moveTo(d, a); ctx.lineTo(b, a); ctx.lineTo(b, c)
                ctx.moveTo(c, b); ctx.lineTo(a, b); ctx.lineTo(a, d)
                ctx.moveTo(d, b); ctx.lineTo(b, b); ctx.lineTo(b, d)
            } else if (symbol === "chapters") {
                ctx.rect(3, 3, 18, 18)
                for (let y = 7; y <= 17; y += 5) {
                    ctx.moveTo(7, y); ctx.lineTo(7.5, y)
                    ctx.moveTo(11, y); ctx.lineTo(17, y)
                }
            } else if (symbol === "menu") {
                for (let y = 6; y <= 18; y += 6) {
                    ctx.moveTo(3, y); ctx.lineTo(21, y)
                }
            }
            ctx.stroke()
        }
    }

    component ControlButton: Basic.ToolButton {
        id: control
        required property string symbol
        implicitWidth: 32
        implicitHeight: 36
        display: AbstractButton.IconOnly
        hoverEnabled: true
        opacity: enabled ? 1 : 0.35
        Accessible.name: text
        contentItem: Item {
            PlayerIcon { anchors.centerIn: parent; symbol: control.symbol }
        }
        background: Rectangle {
            radius: 4
            color: control.down ? "#25ffffff" : control.hovered || control.visualFocus ? "#12ffffff" : "transparent"
        }
    }

    Item {
        id: panel
        anchors.fill: parent
        opacity: root.controlsVisible ? 1 : 0
        visible: opacity > 0
        enabled: root.controlsVisible
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(parent.height + 24, root.m_mpv.height)
            gradient: Gradient {
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 0.35; color: "#42000000" }
                GradientStop { position: 0.60; color: "#c0000000" }
                GradientStop { position: 1; color: "#d9000000" }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onWheel: wheel => wheel.accepted = true
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.width < 600 ? 10 : 20
            anchors.rightMargin: root.width < 600 ? 10 : 20
            anchors.bottomMargin: 10
            height: 36
            spacing: root.width < 600 ? 4 : 8

            HamburgerMenu {
                id: hamburgerMenu
                m_mpv: root.m_mpv
                m_menuBarLoader: root.m_menuBarLoader
                position: HamburgerMenu.Position.Footer
                visible: !root.m_header.visible
                implicitWidth: 32
                implicitHeight: 36
                contentItem: Item {
                    PlayerIcon { anchors.centerIn: parent; symbol: "menu" }
                }
                background: Rectangle { radius: 4; color: hamburgerMenu.hovered ? "#12ffffff" : "transparent" }
            }
            ControlButton {
                symbol: "previous"
                action: HarunaApp.actions.playPreviousAction
                enabled: root.playlistsManager.activePlaylist.itemCount > 1
                visible: root.width >= 600
            }
            ControlButton {
                symbol: root.m_mpv.pause ? "play" : "pause"
                action: HarunaApp.actions.playPauseAction
            }
            ControlButton {
                symbol: "next"
                action: HarunaApp.actions.playNextAction
                enabled: root.playlistsManager.activePlaylist.itemCount > 1
                visible: root.width >= 600
            }
            HProgressBar {
                id: progressBar
                m_mpv: root.m_mpv
                Layout.fillWidth: true
                Layout.minimumWidth: 24
                Layout.preferredHeight: 28
                Layout.leftMargin: 6
                Layout.rightMargin: 6
            }
            Label {
                text: root.width >= 720
                      ? "%1 / %2".arg(root.m_mpv.formattedPosition).arg(root.m_mpv.formattedDuration)
                      : root.m_mpv.formattedPosition
                color: "#ffffff"
                font.pixelSize: 12
                style: Text.Outline
                styleColor: "#80000000"
                visible: root.width >= 360
            }
            ControlButton {
                symbol: "chapters"
                text: KI18n.i18nc("@info:tooltip", "Open chapters menu")
                visible: root.m_mpv.chaptersModel.rowCount > 0 && root.width >= 800
                onClicked: progressBar.openChapterPopup(this)
            }
            ControlButton {
                symbol: root.m_mpv.mute || root.m_mpv.volume === 0 ? "muted" : "volume"
                action: HarunaApp.actions.muteAction
                visible: root.width >= 360
            }
            VolumeSlider {
                id: volumeSlider
                m_mpv: root.m_mpv
                visible: root.width >= 900
                Layout.preferredWidth: 64
                Layout.preferredHeight: 30
            }
            ControlButton {
                symbol: root.mainWindow.isMaximized() ? "restore" : "maximize"
                text: root.mainWindow.isMaximized()
                      ? KI18n.i18nc("@action:button", "Restore") : KI18n.i18nc("@action:button", "Maximize")
                visible: !root.mainWindow.isFullScreen()
                onClicked: root.mainWindow.toggleMaximized()
            }
            ControlButton {
                symbol: root.mainWindow.isFullScreen() ? "leaveFullscreen" : "fullscreen"
                action: HarunaApp.actions.toggleFullscreenAction
            }
        }
    }
}
