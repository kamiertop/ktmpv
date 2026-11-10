/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.haruna
import org.kde.haruna.settings

PlaylistItemDelegate {
    id: root

    property bool showThumbnail: false
    readonly property string displayTitle: PlaylistSettings.showMediaTitle ? titleWithFallback : nameWithFallbackRole

    implicitHeight: showThumbnail ? 72 : 64

    contentItem: Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 28

                Label {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "▶" : (PlaylistSettings.showRowNumber ? root.rowNumber : "")
                    color: root.isPlaying ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                    font.pixelSize: 11
                    visible: !root.hovered
                }
                Kirigami.ListItemDragHandle {
                    anchors.centerIn: parent
                    visible: root.hovered
                    width: 20
                    height: 28
                    listItem: root.dragRect
                    listView: root.ListView.view
                    onMoveRequested: function(oldIndex, newIndex) {
                        root.selectItem(oldIndex, PlaylistFilterProxyModel.Single)
                        root.moveItems(oldIndex, newIndex)
                    }
                    onDragActiveChanged: root.cacheItem()
                }
            }

            Rectangle {
                visible: root.showThumbnail
                Layout.preferredWidth: 64
                Layout.preferredHeight: 44
                radius: 6
                color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
                clip: true
                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.showThumbnail ? "image://thumbnail/%1".arg(root.path) : ""
                    sourceSize.width: 128
                    sourceSize.height: 88
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                LabelWithTooltip {
                    text: root.displayTitle
                    toolTipText: root.displayTitle
                    color: root.getLabelColor()
                    font.pointSize: root.getFontSize()
                    font.weight: root.isPlaying ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label {
                        text: root.nameWithFallbackRole !== root.displayTitle ? root.nameWithFallbackRole : root.formattedDuration
                        color: Kirigami.Theme.disabledTextColor
                        font.pointSize: Math.max(9, root.getFontSize() - 2)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Label {
                        text: root.formattedDuration
                        visible: root.nameWithFallbackRole !== root.displayTitle
                        color: Kirigami.Theme.disabledTextColor
                        font.pointSize: Math.max(9, root.getFontSize() - 2)
                    }
                }
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 42
            anchors.rightMargin: 12
            anchors.bottomMargin: 5
            height: 2
            radius: 1
            visible: PlaybackSettings.restoreFilePosition && progress > 0
            readonly property real progress: Math.max(0, Math.min(1,
                root.isPlaying && root.m_mpv.duration > 0
                ? root.m_mpv.position / root.m_mpv.duration : root.playbackPosition))
            color: Qt.alpha(Kirigami.Theme.highlightColor, 0.12)
            Rectangle {
                width: parent.width * parent.progress
                height: parent.height
                radius: 1
                color: Qt.alpha(Kirigami.Theme.highlightColor, 0.65)
            }
        }
    }
}
