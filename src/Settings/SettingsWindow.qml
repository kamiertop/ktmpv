/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

import org.kde.ki18n
import org.kde.kirigami as Kirigami

import org.kde.haruna

Loader {
    id: root

    required property MpvVideo m_mpv

    property int activePage: SettingsWindow.Page.General

    enum Page {
        General = 0,
        Osd,
        Playback,
        Video,
        Audio,
        Subtitles,
        Playlist,
        Mouse,
        Shortcuts,
        CustomCommands,
        Database,
        Debug,
        About,
        None
    }

    function openSettingPage(page: int) : void {
        if (page !== SettingsWindow.Page.None) {
            root.activePage = page
        }
        if (!root.active) {
            root.active = true
            return
        }
        if (root.status !== Loader.Ready) {
            return
        }
        const window = root.item as Kirigami.ApplicationWindow
        window.showPage(root.activePage)
        window.show()
        window.raise()
    }

    onLoaded: openSettingPage(SettingsWindow.Page.None)
    onActivePageChanged: {
        if (root.status === Loader.Ready) {
            root.item.showPage(root.activePage)
        }
    }

    active: false
    asynchronous: true
    sourceComponent: Kirigami.ApplicationWindow {
        id: settingsWindow

        property string settingsPath: "qrc:/qt/qml/org/kde/haruna/settings"
        property int loadedPage: SettingsWindow.Page.None
        readonly property list<string> pageFiles: [
            "GeneralPage.qml", "OsdPage.qml", "PlaybackPage.qml", "VideoPage.qml",
            "AudioPage.qml", "SubtitlesPage.qml", "PlaylistPage.qml", "MousePage.qml",
            "ShortcutsPage.qml", "CustomCommandsPage.qml", "DatabasePage.qml", "DebugPage.qml",
            "AboutSettingsPage.qml"
        ]

        function showPage(page: int): void {
            if (page < 0 || page > SettingsWindow.Page.About
                    || (page === loadedPage && pageStack.depth > 1)) {
                return
            }
            const component = Qt.createComponent(`${settingsPath}/${pageFiles[page]}`)
            if (component.status !== Component.Ready) {
                console.warn("Could not load settings page", pageFiles[page], component.errorString())
                component.destroy()
                return
            }
            const properties = {title: settingsPagesList.pages[page].text}
            if (page === SettingsWindow.Page.Video) {
                properties.m_mpv = root.m_mpv
            }
            // PageRow's URL factory parents new items to an internal QtObject.
            // Create with a visual parent first, then pass the item to PageRow.
            const item = component.createObject(pageStack, properties)
            if (!item) {
                console.warn("Could not create settings page", pageFiles[page], component.errorString())
                component.destroy()
                return
            }
            component.destroy()
            const previousPage = pageStack.get(1)
            if (previousPage) {
                pageStack.currentIndex = 1
                pageStack.replace(item)
                previousPage.destroy()
            } else {
                pageStack.push(item)
            }
            loadedPage = page
        }


        width: 880
        height: 640
        minimumWidth: 750
        minimumHeight: 400
        title: KI18n.i18nc("@title:window", "Settings")
        transientParent: null
        pageStack.initialPage: Kirigami.ScrollablePage {
            id: navigationPage
            globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.045)
                }
            }

            ColumnLayout {
                id: settingsPagesList

                property list<Kirigami.Action> pages: [
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "General")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.General
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Osd")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Osd
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Playback")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Playback
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Video")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Video
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Audio")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Audio
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Subtitles")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Subtitles
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Playlist")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Playlist
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Mouse")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Mouse
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Shortcuts")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Shortcuts
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Custom Commands")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.CustomCommands
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Database")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Database
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "Debug")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.Debug
                        }
                    },
                    Kirigami.Action {
                        text: KI18n.i18nc("@action", "About")
                        onTriggered: {
                            root.activePage = SettingsWindow.Page.About
                        }
                    }
                ]

                width: navigationPage.availableWidth
                spacing: 3

                Item { Layout.preferredHeight: 9 }

                Repeater {
                    id: navigationEntries
                    model: settingsPagesList.pages
                    delegate: Basic.ItemDelegate {
                        id: delegate

                        required property int index
                        required property Action modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 37
                        leftPadding: 22
                        rightPadding: 22
                        hoverEnabled: true
                        action: delegate.modelData
                        Keys.onUpPressed: navigationEntries.itemAt(Math.max(0, index - 1))?.forceActiveFocus()
                        Keys.onDownPressed: navigationEntries.itemAt(Math.min(navigationEntries.count - 1, index + 1))?.forceActiveFocus()
                        highlighted: delegate.index === root.activePage
                        palette.text: Kirigami.Theme.textColor
                        palette.buttonText: Kirigami.Theme.textColor
                        palette.highlightedText: Kirigami.Theme.textColor
                        font.weight: highlighted ? Font.DemiBold : Font.Normal
                        background: Item {
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                radius: 8
                                color: Qt.alpha(Kirigami.Theme.textColor, delegate.down ? 0.20
                                                : delegate.highlighted ? 0.15 : delegate.hovered ? 0.10 : 0)
                                border.width: delegate.visualFocus ? 1 : 0
                                border.color: Kirigami.Theme.highlightColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 9 }
            }
        }

        onClosing: root.active = false

        Component.onCompleted: {
            HarunaApp.setupEventFilter(settingsWindow)
            pageStack.columnView.columnWidth = 208
        }

        Shortcut {
            sequence: "Esc"
            enabled: HarunaApp.actionsEnabled
            onActivated: settingsWindow.close()
        }
    }
}
