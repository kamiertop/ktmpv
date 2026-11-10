/*
 * SPDX-FileCopyrightText: 2023 George Florea Bănuș <georgefb899@gmail.com>
 * SPDX-FileCopyrightText: 2025 Muhammet Sadık Uğursoy <sadikugursoy@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

import org.kde.ki18n
import org.kde.kirigami as Kirigami

import org.kde.haruna
import org.kde.haruna.playlist
import org.kde.haruna.utilities
import org.kde.haruna.settings
import org.kde.haruna.youtube

ResizeablePage {
    id: root

    required property MpvVideo m_mpv
    property alias advancedSortWindow: advancedSortWindow
    property alias scrollPositionTimer: scrollPositionTimer
    property alias playlistView: playlistView

    property PlaylistsManager manager: PlaylistsManager {}

    edge: PlaylistSettings.position === "right" ? Qt.RightEdge : Qt.LeftEdge
    customWidth: PlaylistSettings.playlistWidth
    width: limitWidth(customWidth * fsScale)

    function limitWidth(pWidth) {
        return Math.min(Math.max(pWidth, 260), mainWindowWidth - 50)
    }

    onResize: function (delta) {
        // invert the drag delta when the playlist is anchored to the right
        // dragging left (pX is negative) expands a right-aligned playlist, but shrinks a left-aligned one
        const widthDelta = root.edge === Qt.RightEdge ? delta * -1 : delta;
        root.customWidth = root.limitWidth(root.customWidth + widthDelta)
    }

    onSaveWidth: {
        PlaylistSettings.playlistWidth = root.customWidth ? root.customWidth : 260
        PlaylistSettings.save()
    }

    state: PlaylistSettings.rememberState
           ? (PlaylistSettings.visible ? "visible" : "hidden")
           : "hidden"

    onStateChanged: {
        PlaylistSettings.visible = state === "visible" ? true : false
        PlaylistSettings.save()
    }

    PlaylistAdvancedSortWindow {
        id: advancedSortWindow

        playlistsManager: root.manager
    }

    component SidebarButton: Basic.ToolButton {
        id: control
        implicitWidth: 30
        implicitHeight: 30
        icon.width: 16
        icon.height: 16
        icon.color: Kirigami.Theme.textColor
        display: AbstractButton.IconOnly
        hoverEnabled: true
        Accessible.name: text
        ToolTip.visible: hovered && text.length > 0
        ToolTip.text: text
        ToolTip.delay: 600
        background: Rectangle {
            radius: 6
            color: Qt.alpha(Kirigami.Theme.textColor, control.down ? 0.14 : control.hovered ? 0.08 : 0)
            border.width: control.visualFocus ? 2 : 0
            border.color: Kirigami.Theme.highlightColor
        }
    }

    function addFiles() {
        fileDialog.fileType = "video"
        fileDialog.fileMode = FileDialog.OpenFiles
        fileDialog.open()
    }

    Item {
        id: playlistActions
        visible: false
        ActionGroup { id: sortOrderGroup }
        ActionGroup { id: sortPresetGroup }
        property list<QtObject> actions: [
            Kirigami.Action {
                id: newPlaylistAction
                text: KI18n.i18nc("@action:button", "Add new playlist")
                icon.name: "list-add"
                displayHint: Kirigami.DisplayHint.AlwaysHide
                onTriggered: addPlaylistPopup.open()
            },
            Kirigami.Action {
                text: KI18n.i18nc("@action:inmenu", "Rename")
                icon.name: "edit-rename"
                displayHint: Kirigami.DisplayHint.AlwaysHide
                enabled: root.manager.visibleIndex > 0
                onTriggered: root.manager.renamePlaylist(root.manager.visibleIndex)
            },
            Kirigami.Action {
                text: KI18n.i18nc("@action:inmenu", "Remove playlist")
                icon.name: "list-remove"
                displayHint: Kirigami.DisplayHint.AlwaysHide
                enabled: root.manager.visibleIndex > 0
                onTriggered: root.manager.removePlaylist(root.manager.visibleIndex)
            },
            Kirigami.Action {
                id: addMediaAction
                text: KI18n.i18nc("@action:button", "Add…")
                displayHint: Kirigami.DisplayHint.AlwaysHide
                icon.name: "list-add"
                icon.width: root.buttonSize
                icon.height: root.buttonSize
                Kirigami.Action {
                    id: addFolderAction
                    text: KI18n.i18nc("@action:button", "Folder")
                    onTriggered: {
                        const item = folderDialogComponent.createObject(root)
                        const folderDialog = item as FolderDialog
                        folderDialog.open()
                    }
                }
                Kirigami.Action {
                    id: addFilesAction
                    text: KI18n.i18nc("@action:button", "Files")
                    onTriggered: {
                        fileDialog.fileType = "video"
                        fileDialog.fileMode = FileDialog.OpenFiles
                        fileDialog.open()
                    }
                }
                Kirigami.Action {
                    id: addUrlAction
                    text: KI18n.i18nc("@action:button", "URL")
                    onTriggered: {
                        if (addUrlPopup.opened) {
                            addUrlPopup.close()
                        } else {
                            addUrlPopup.open()
                        }
                    }
                }
                Kirigami.Action {
                    id: importPlaylistAction
                    text: KI18n.i18nc("@action:button", "Playlist")
                    onTriggered: {
                        fileDialog.fileType = "playlist"
                        fileDialog.fileMode = FileDialog.OpenFile
                        fileDialog.open()
                    }
                }
            },
            Kirigami.Action {
                id: sortAction
                text: KI18n.i18nc("@action:button", "Sort")
                displayHint: Kirigami.DisplayHint.AlwaysHide
                icon.name: "view-sort"
                icon.width: root.buttonSize
                icon.height: root.buttonSize

                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Ascending")
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortOrder === Qt.AscendingOrder

                    icon {
                        name: "view-sort-ascending-name"
                        width: root.buttonSize
                        height: root.buttonSize
                    }

                    onTriggered: {
                        root.manager.visiblePlaylist.sortOrder = Qt.AscendingOrder
                    }

                    ActionGroup.group: sortOrderGroup
                }
                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Descending")
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortOrder === Qt.DescendingOrder

                    icon {
                        name: "view-sort-descending-name"
                        width: root.buttonSize
                        height: root.buttonSize
                    }
                    onTriggered: {
                        root.manager.visiblePlaylist.sortOrder = Qt.DescendingOrder
                    }

                    ActionGroup.group: sortOrderGroup
                }

                Kirigami.Action {
                    separator: true
                }

                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.None
                    text: KI18n.i18nc("@action:button", "None")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.None
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.FileName
                    text: KI18n.i18nc("@action:button", "File Name")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.FileName
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.Title
                    text: KI18n.i18nc("@action:button", "Title")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.Title
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.Duration
                    text: KI18n.i18nc("@action:button", "Duration")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.Duration
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.Date
                    text: KI18n.i18nc("@action:button", "Modified Date")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.Date
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.FileSize
                    text: KI18n.i18nc("@action:button", "File Size")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.FileSize
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.TrackNo
                    text: KI18n.i18nc("@action:button, as in 'Track no on a Audio CD', not 'subtitle track'", "Track No")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.TrackNo
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.SampleRate
                    text: KI18n.i18nc("@action:button", "Sample Rate")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.SampleRate
                    }
                    ActionGroup.group: sortPresetGroup
                }
                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.Bitrate
                    text: KI18n.i18nc("@action:button", "Bitrate")

                    onTriggered: {
                        root.manager.visiblePlaylist.sortPreset = PlaylistSortProxyModel.Bitrate
                    }
                    ActionGroup.group: sortPresetGroup
                }

                Kirigami.Action {
                    separator: true
                }

                Kirigami.Action {
                    checkable: true
                    checked: root.manager.visiblePlaylist.sortPreset === PlaylistSortProxyModel.Custom
                    text: KI18n.i18nc("@action:button", "Custom…")

                    onTriggered: {
                        root.advancedSortWindow.open()
                        root.manager.visiblePlaylist.itemsSorted()
                    }
                    ActionGroup.group: sortPresetGroup
                }
            },

            Kirigami.Action {
                id: playbackAction
                text: KI18n.i18nc("@action:button", "Playback")
                icon.name: "media-playback-start"
                icon.width: root.buttonSize
                icon.height: root.buttonSize
                displayHint: Kirigami.DisplayHint.AlwaysHide
                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Repeat playlist")
                    icon.name: "media-playlist-repeat"
                    autoExclusive: true
                    checkable: true
                    checked: PlaylistSettings.playbackBehavior === "RepeatPlaylist"
                    onTriggered: {
                        PlaylistSettings.playbackBehavior = "RepeatPlaylist"
                        PlaylistSettings.save()
                    }
                }
                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Stop after last item")
                    autoExclusive: true
                    checkable: true
                    checked: PlaylistSettings.playbackBehavior === "StopAfterLast"
                    onTriggered: {
                        PlaylistSettings.playbackBehavior = "StopAfterLast"
                        PlaylistSettings.save()
                    }
                }
                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Repeat item")
                    autoExclusive: true
                    checkable: true
                    checked: PlaylistSettings.playbackBehavior === "RepeatItem"
                    icon.name: "media-playlist-repeat-song"
                    onTriggered: {
                        PlaylistSettings.playbackBehavior = "RepeatItem"
                        PlaylistSettings.save()
                    }
                }
                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Stop after item")
                    autoExclusive: true
                    checkable: true
                    checked: PlaylistSettings.playbackBehavior === "StopAfterItem"
                    onTriggered: {
                        PlaylistSettings.playbackBehavior = "StopAfterItem"
                        PlaylistSettings.save()
                    }
                }
                Kirigami.Action {
                    text: KI18n.i18nc("@action:button", "Random Playback")
                    checkable: true
                    enabled: ["StopAfterLast", "RepeatPlaylist"].includes(PlaylistSettings.playbackBehavior)
                    checked: PlaylistSettings.randomPlayback
                    icon.name: "randomize"
                    onTriggered: {
                        PlaylistSettings.randomPlayback = checked
                        PlaylistSettings.save()
                    }
                }
            },
            Kirigami.Action {
                text: KI18n.i18nc("@action:button", "Clear")
                icon.name: "edit-clear-all"
                displayHint: Kirigami.DisplayHint.AlwaysHide
                onTriggered: {
                    root.manager.visiblePlaylist.clear()
                }
            },
            Kirigami.Action {
                text: KI18n.i18nc("@action:button", "Save As")
                icon.name: "document-save-as"
                displayHint: Kirigami.DisplayHint.AlwaysHide
                onTriggered: {
                    fileDialog.fileType = "playlist"
                    fileDialog.fileMode = FileDialog.SaveFile
                    fileDialog.open()
                }
            },
            Kirigami.Action {
                text: KI18n.i18nc("@action:inmenu", "Update all metadata")
                icon.name: "view-refresh"
                displayHint: Kirigami.DisplayHint.AlwaysHide
                enabled: !root.manager.visiblePlaylist.isUpdatingMetadata
                onTriggered: {
                    root.manager.visiblePlaylist.updateMetadata()
                }
                tooltip: (GeneralSettings.showExplanatoryToolTips || HarunaApp.isAltKeyPressed)
                         ? KI18n.i18nc("@info:tooltip", "Update metadata for all files in the playlist\n\n"+
                                       "Update metadata in the database with metadata inside the file.\n" +
                                       "Metadata is stored in the database for faster retrieval.")
                         : ""
            }
        ]
    }

    header: ToolBar {
        id: toolbar

        leftPadding: 10
        rightPadding: 10
        topPadding: 2
        bottomPadding: 8
        background: Rectangle { color: root.Kirigami.Theme.backgroundColor }
        contentItem: ColumnLayout {
            spacing: 4

            RowLayout {
                spacing: 3
                SidebarButton {
                    action: addFilesAction
                    icon.name: "list-add"
                }
                SidebarButton { action: addFolderAction; icon.name: "folder-open" }
                SidebarButton { action: addUrlAction; icon.name: "link" }
                SidebarButton { action: importPlaylistAction; icon.name: "view-media-playlist" }
                SidebarButton {
                    text: sortAction.text
                    icon.name: "view-sort"
                    onClicked: sortMenu.open()
                    PlaylistActionsMenu {
                        id: sortMenu
                        y: parent.height + 4
                        actions: sortAction.children
                        submenuComponent: Component { PlaylistActionsMenu {} }
                    }
                }
                SidebarButton {
                    text: playbackAction.text
                    icon.name: "media-playlist-repeat"
                    onClicked: playbackMenu.open()
                    PlaylistActionsMenu {
                        id: playbackMenu
                        y: parent.height + 4
                        actions: playbackAction.children
                        submenuComponent: Component { PlaylistActionsMenu {} }
                    }
                }
                Item { Layout.fillWidth: true }
                SidebarButton {
                    text: KI18n.i18nc("@action:button", "More actions")
                    icon.name: "overflow-menu"
                    onClicked: sidebarMenu.open()
                    PlaylistActionsMenu {
                        id: sidebarMenu
                        y: parent.height + 4
                        actions: playlistActions.actions.filter(action => action !== addMediaAction
                                                                 && action !== sortAction
                                                                 && action !== playbackAction
                                                                 && action !== newPlaylistAction)
                        submenuComponent: Component { PlaylistActionsMenu {} }
                    }
                }
            }

            RowLayout {
                spacing: 4
                Basic.ComboBox {
                    id: playlistSelector
                    Layout.fillWidth: true
                    implicitHeight: 30
                    model: root.manager
                    textRole: "name"
                    currentIndex: root.manager.visibleIndex
                    onActivated: root.manager.visibleIndex = currentIndex
                    displayText: currentIndex === 0
                                 ? KI18n.i18nc("@label:title name of default playlist tab", "Default")
                                 : currentText
                    leftPadding: 8
                    rightPadding: 26
                    hoverEnabled: true
                    background: Rectangle {
                        radius: 6
                        color: Qt.alpha(Kirigami.Theme.textColor, playlistSelector.hovered || playlistSelector.down ? 0.055 : 0)
                        border.width: playlistSelector.visualFocus ? 2 : 0
                        border.color: Kirigami.Theme.highlightColor
                    }
                    contentItem: Label {
                        text: playlistSelector.displayText
                        color: Kirigami.Theme.textColor
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font.pointSize: 11
                        font.weight: Font.Medium
                    }
                    indicator: Kirigami.Icon {
                        x: playlistSelector.width - width - 8
                        y: (playlistSelector.height - height) / 2
                        width: 12
                        height: 12
                        source: "arrow-down"
                        color: Kirigami.Theme.disabledTextColor
                    }
                    delegate: Basic.ItemDelegate {
                        id: playlistOption
                        required property int index
                        required property string name
                        width: playlistSelector.width
                        text: index === 0
                              ? KI18n.i18nc("@label:title name of default playlist tab", "Default") : name
                        highlighted: playlistSelector.highlightedIndex === index
                        contentItem: Label {
                            text: playlistOption.text
                            color: Kirigami.Theme.textColor
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        background: Rectangle {
                            radius: 6
                            color: playlistOption.highlighted ? Qt.alpha(Kirigami.Theme.highlightColor, 0.12) : "transparent"
                        }
                    }
                }
                Label {
                    text: root.manager.visiblePlaylist.itemCount
                    color: Kirigami.Theme.disabledTextColor
                    font.pointSize: 9
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                }
                SidebarButton { action: newPlaylistAction; icon.name: "list-add" }
            }

            Basic.TextField {
                id: searchField
                Layout.fillWidth: true
                implicitHeight: 30
                leftPadding: 28
                rightPadding: 30
                placeholderText: KI18n.i18nc("@action:button", "Search")
                color: Kirigami.Theme.textColor
                placeholderTextColor: Kirigami.Theme.disabledTextColor
                font.pointSize: 10
                text: root.manager.visiblePlaylist.searchText
                selectByMouse: true
                onTextEdited: searchDelay.restart()
                background: Item {
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: searchField.activeFocus ? 2 : 1
                        color: searchField.activeFocus ? Kirigami.Theme.highlightColor
                               : Qt.alpha(Kirigami.Theme.textColor, 0.10)
                    }
                }
                Kirigami.Icon {
                    x: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    source: "search"
                    color: Kirigami.Theme.disabledTextColor
                }
                SidebarButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchField.text.length > 0
                    text: KI18n.i18nc("@action:button", "Clear")
                    icon.name: "edit-clear"
                    onClicked: {
                        searchDelay.stop()
                        root.manager.visiblePlaylist.searchText = ""
                        searchField.text = ""
                        searchField.forceActiveFocus()
                    }
                }
                Timer {
                    id: searchDelay
                    interval: 150
                    onTriggered: {
                        root.manager.visiblePlaylist.searchText = searchField.text
                        playlistView.positionViewAtIndex(0, ListView.Beginning)
                    }
                }
                Connections {
                    target: root.manager
                    function onVisiblePlaylistChanged() { searchDelay.stop() }
                }
            }
        }
    }

    InputPopup {
        id: addUrlPopup

        x: Kirigami.Units.largeSpacing
        y: Kirigami.Units.largeSpacing
        width: toolbar.width - Kirigami.Units.largeSpacing * 2
        buttonText: KI18n.i18nc("@action:button", "Add")
        warningText: youtube.hasYoutubeDl()
                     ? ""
                     : KI18n.i18nc("@info", "Neither <a href=\"https://github.com/yt-dlp/yt-dlp\">yt-dlp</a> nor <a href=\"https://github.com/ytdl-org/youtube-dl\">youtube-dl</a> was found.")

        onSubmitted: function(url) {
            root.manager.visiblePlaylist.addItem(url, PlaylistModel.Append)
        }

        YouTube {
            id: youtube
        }
    }

    InputPopup {
        id: addPlaylistPopup

        x: Kirigami.Units.largeSpacing
        y: Kirigami.Units.largeSpacing
        width: toolbar.width - Kirigami.Units.largeSpacing * 2
        placeholderText: KI18n.i18nc("@placeholder", "playlist name")
        buttonText: KI18n.i18nc("@action:button", "Add")

        onSubmitted: function(plName) {
            root.manager.createNewPlaylist(plName)
        }
    }

    pageContent: [
        DropArea {
            id: playlistDropArea

            anchors.fill: playlistScrollView
            keys: ["text/uri-list"]

            onDropped: function(drop) {
                if (!containsDrag) {
                    return
                }
                root.manager.visiblePlaylist.addFilesAndFolders(drop.urls, PlaylistModel.Append)
            }
        },

        ScrollView {
            id: playlistScrollView

            z: 20
            anchors.fill: parent
            anchors {
                leftMargin: 12
                rightMargin: 12
            }

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: playlistView

                property bool startupScrollDone: false

                // set bottomMargin so that the footer doesn't block playlist items
                bottomMargin: 16
                topMargin: 4

                model: root.manager.visiblePlaylist
                onModelChanged: {
                    Qt.callLater(root.manager.visiblePlaylist.refreshData)
                }

                reuseItems: true
                spacing: 4
                currentIndex: root.manager.visiblePlaylist.getPlayingItem()
                highlightFollowsCurrentItem: false

                moveDisplaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Kirigami.Units.shortDuration
                    }
                }

                delegate: {
                    switch (PlaylistSettings.style) {
                    case "default":
                        return playlistItemSimple
                    case "withThumbnails":
                        return playlistItemWithThumbnail
                    default:
                        return playlistItemSimple
                    }
                }

                section {
                    property: "section"
                    delegate: PlaylistSectionDelegate {
                        model: root.manager.visiblePlaylist
                    }
                }

                onCountChanged: {
                    if (startupScrollDone || count <= 0) {
                        return
                    }
                    startupScrollDone = true
                    Qt.callLater(positionViewAtIndex, currentIndex, ListView.Beginning)
                }

                ContextMenu.menu: Menu {
                    MenuItem {
                        text: KI18n.i18nc("@action:inmenu", "Select All")
                        onClicked: root.manager.visiblePlaylist.selectItem(0, PlaylistFilterProxyModel.All)
                    }

                    MenuItem {
                        text: KI18n.i18nc("@action:inmenu", "Deselect All")
                        onClicked: root.manager.visiblePlaylist.selectItem(0, PlaylistFilterProxyModel.Clear)
                    }

                    MenuItem {
                        text: KI18n.i18nc("@action:inmenu", "Invert Selection")
                        onClicked: root.manager.visiblePlaylist.selectItem(0, PlaylistFilterProxyModel.Invert)
                    }

                    MenuSeparator {}

                    MenuItem {
                        text: KI18n.i18nc("@action:inmenu", "Scroll to Playing Item")
                        onClicked: {
                            const index = root.manager.visiblePlaylist.getPlayingItem()
                            playlistView.positionViewAtIndex(index, ListView.Beginning)
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.MiddleButton
                    onSingleTapped: function(eventPoint, mouseButton) {
                        const index = root.manager.visiblePlaylist.getPlayingItem()
                        playlistView.positionViewAtIndex(index, ListView.Beginning)
                    }
                }
            }
        },

        ColumnLayout {
            z: 21
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 48)
            spacing: 10
            visible: playlistView.count === 0

            Label {
                text: searchField.text.length > 0
                      ? KI18n.i18nc("@info:placeholder", "No matching files")
                      : KI18n.i18nc("@info:placeholder", "Your playlist is empty")
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Label {
                text: KI18n.i18nc("@info:placeholder", "Add files or drop them here")
                visible: searchField.text.length === 0
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: 10
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Basic.Button {
                id: emptyAddButton
                visible: searchField.text.length === 0
                text: KI18n.i18nc("@action:button", "Add…")
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                implicitHeight: 36
                leftPadding: 20
                rightPadding: 20
                onClicked: root.addFiles()
                contentItem: Label {
                    text: emptyAddButton.text
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.weight: Font.Medium
                }
                background: Rectangle {
                    radius: 8
                    color: Qt.alpha(Kirigami.Theme.textColor, emptyAddButton.down ? 0.14 : emptyAddButton.hovered ? 0.1 : 0.06)
                    border.width: emptyAddButton.visualFocus ? 2 : 0
                    border.color: Kirigami.Theme.highlightColor
                }
            }
        },

        Component {
            id: playlistItemWithThumbnail
            PlaylistItemWithThumbnail {
                m_mpv: root.m_mpv
                playlistsManager: root.manager
            }
        },

        Component {
            id: playlistItemSimple
            PlaylistItem {
                m_mpv: root.m_mpv
                playlistsManager: root.manager
            }
        },

        // without a timer the scroll position is incorrect
        Timer {
            id: scrollPositionTimer

            interval: 100
            running: false
            repeat: false

            onTriggered: {
                playlistView.positionViewAtIndex(playlistView.model.playingVideo, ListView.Beginning)
            }
        },

        ShaderEffectSource {
            id: shaderEffect

            visible: PlaylistSettings.overlayVideo
            anchors.fill: playlistScrollView
            sourceItem: root.m_mpv
            sourceRect: {
                var rectTopLeftY = toolbar.visible ? toolbar.height : 0
                if (PlaylistSettings.position === "right") {
                    return Qt.rect(
                                root.x - root.m_mpv.x,
                                root.m_mpv.y + rectTopLeftY,
                                root.width,
                                root.height - rectTopLeftY
                                )
                } else {
                    return Qt.rect(
                                root.x,
                                rectTopLeftY,
                                root.width,
                                root.height - rectTopLeftY
                                )
                }
            }
        },

        FastBlur {
            visible: PlaylistSettings.overlayVideo
            anchors.fill: shaderEffect
            radius: 100
            source: shaderEffect
        }
    ]

    FileDialog {
        id: fileDialog

        property string fileType: "video"

        title: KI18n.i18nc("@title:window", "Select file")
        currentFolder: GeneralSettings.fileDialogLastLocation
        fileMode: FileDialog.OpenFile
        nameFilters: {
            if (fileType === "playlist" ) {
                return ["m3u (*.m3u *.m3u8)"]
            } else {
                return [
                    KI18n.i18nc("@item:inlistbox", "Video files (%1)", "*.mp4 *.mkv *.webm *.avi *.mov *.m4v *.mpg *.mpeg *.m2v *.ts *.mts *.m2ts *.vob *.ogv *.flv *.f4v *.wmv *.asf *.rm *.rmvb *.3gp *.3g2 *.divx *.hevc *.h264 *.h265"),
                    KI18n.i18nc("@item:inlistbox", "Audio files (%1)", "*.mp3 *.flac *.ogg *.opus *.wav *.m4a *.aac *.wma *.aiff *.ape *.ac3 *.dts *.mka"),
                    KI18n.i18nc("@item:inlistbox", "All files (%1)", "*")
                ]
            }
        }

        onAccepted: {
            switch (fileType) {
            case "video":
                root.manager.visiblePlaylist.addItems(fileDialog.selectedFiles, PlaylistModel.Append)
                break
            case "playlist":
                if (fileMode === FileDialog.OpenFile) {
                    root.manager.visiblePlaylist.addItem(fileDialog.selectedFile, PlaylistModel.Append)
                } else {
                    root.manager.visiblePlaylist.saveM3uFile(fileDialog.selectedFile)
                }

                break
            }
            GeneralSettings.fileDialogLastLocation = PathUtils.parentUrl(fileDialog.selectedFile)
            GeneralSettings.save()
        }
        onRejected: root.m_mpv.focus = true
        onVisibleChanged: {
            if (visible) {
                selectedNameFilter.index = 0
            }
            HarunaApp.actionsEnabled = !visible
        }
    }

    Component {
        id: folderDialogComponent

        FolderDialog {
            id: folderDialog

            currentFolder: GeneralSettings.fileDialogLastLocation
            onRejected: {
                root.m_mpv.focus = true
                destroy()
            }
            onAccepted: {
                root.manager.visiblePlaylist.addFilesAndFolders([folderDialog.selectedFolder], PlaylistModel.Append)
                GeneralSettings.fileDialogLastLocation = PathUtils.parentUrl(folderDialog.selectedFolder)
                GeneralSettings.save()
                destroy()
            }
        }
    }
}
