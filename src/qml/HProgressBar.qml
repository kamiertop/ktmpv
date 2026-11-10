/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

import org.kde.ki18n
import org.kde.kirigami as Kirigami

import org.kde.haruna
import org.kde.haruna.utilities
import org.kde.haruna.settings

RowLayout {
    id: root

    required property MpvVideo m_mpv

    readonly property bool interacting: slider.pressed || progressBarMouseArea.containsMouse || chaptersPopup.visible
    property alias loopIndicator: loopIndicator
    property alias chaptersPopupIsOpen: chaptersPopup.visible
    property bool showChapterMarkers: GeneralSettings.showChapterMarkers
                                      && m_mpv.chaptersModel.rowCount * 20 < width

    function openChapterPopup(triggerItem: Item) {
        const x = (chaptersPopup.width + triggerItem.width) * -0.5
        const globalPoint = root.mapToGlobal(x, 0)
        const localPoint = root.mapFromGlobal(Kirigami.Units.largeSpacing, 0)
        chaptersPopup.x = globalPoint.x < 0 ? localPoint.x : x
        chaptersPopup.open()
    }

    spacing: Kirigami.Units.smallSpacing

    Basic.Slider {
        id: slider

        property bool seekStarted: false
        property bool prePressPause: root.m_mpv.pause
        property double mouseX: 0
        property double requestedPreviewPosition: 0

        function updateTooltip() : string {
            if (progressBarBG.width <= 0 || slider.to <= 0) {
                return ""
            }

            slider.mouseX = progressBarMouseArea.mouseX
            const time = Math.max(0, Math.min(slider.to, progressBarMouseArea.mouseX / progressBarBG.width * slider.to))
            requestPreview(time)
            const chapterTitle = root.m_mpv.chaptersModel.titleAtPosition(time)
            const formattedTime = MiscUtils.formatTime(time)
            timePositionLabel.text = chapterTitle === ""
                    ? formattedTime
                    :`${formattedTime} - ${chapterTitle}`
        }

        function requestPreview(time: real): void {
            requestedPreviewPosition = time
            if (!previewSeekTimer.running) {
                previewSeekTimer.start()
            }
        }

        Timer {
            id: previewSeekTimer
            interval: 50
            onTriggered: previewMpvLoader.position = slider.requestedPreviewPosition
        }

        enabled: root.m_mpv.duration > 0
        from: 0
        to: root.m_mpv.duration
        implicitWidth: root.width
        implicitHeight: root.height
        leftPadding: 0
        rightPadding: 0
        hoverEnabled: true

        Layout.fillWidth: true

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * slider.availableWidth - width / 2
            y: (slider.height - height) / 2
            width: 10
            height: 10
            radius: 5
            color: "#ffffff"
            visible: slider.hovered || slider.pressed || slider.visualFocus
        }

        background: Rectangle {
            id: progressBarBG
            x: slider.leftPadding
            y: (slider.height - height) / 2
            width: slider.availableWidth
            height: 4
            radius: height / 2
            color: "#35ffffff"
            scale: slider.mirrored ? -1 : 1

            Rectangle {
                id: loopIndicator
                property double startPosition: -1
                property double endPosition: -1
                width: endPosition === -1 || root.m_mpv.duration <= 0 ? 1 : Math.max(0, (endPosition / root.m_mpv.duration * progressBarBG.width) - x)
                height: parent.height
                color: Qt.hsla(0, 0, 0, 0.4)
                visible: startPosition !== -1
                x: root.m_mpv.duration > 0 ? startPosition / root.m_mpv.duration * progressBarBG.width : 0
                z: 110
            }

            Repeater {
                model: root.m_mpv.seekableRangesModel
                delegate: Rectangle {
                    required property double start
                    required property double end

                    objectName: "seekableRangeDelegate"

                    x: root.m_mpv.duration > 0 ? start / root.m_mpv.duration * progressBarBG.width : 0
                    y: (progressBarBG.height - height) / 2
                    z: 0
                    width: root.m_mpv.duration > 0 ? Math.max(0, end / root.m_mpv.duration * progressBarBG.width - x) : 0
                    height: parent.height
                    radius: height / 2
                    color: "#55ffffff"
                }
            }

            Rectangle {
                width: slider.position * parent.width
                height: parent.height
                radius: height / 2
                color: "#ffffff"
            }

            Rectangle {
                id: progressBarToolTip

                property int margin: Kirigami.Units.smallSpacing

                x: {
                    const position = slider.pressed && slider.to > 0
                                     ? slider.value / slider.to * progressBarBG.width : slider.mouseX
                    const left = root.m_mpv.mapToItem(progressBarBG, 12, 0).x
                    const right = root.m_mpv.mapToItem(progressBarBG, root.m_mpv.width - 12, 0).x
                    return Math.max(Math.min(left, right), Math.min(position - width / 2, Math.max(left, right) - width))
                }
                y: -height - Kirigami.Units.largeSpacing
                z: 10
                width: layout.width + (margin * 2)
                height: layout.height + (margin * 2)
                visible: (progressBarMouseArea.containsMouse || slider.pressed) && root.m_mpv.duration > 0

                color: "#f025262b"
                radius: 10
                border.width: 1
                border.color: "#25ffffff"

                ColumnLayout {
                    id: layout

                    anchors.centerIn: parent

                    Loader {
                        id: previewMpvLoader

                        property string file: root.m_mpv.currentUrl
                        property double position: 0
                        property double aspectRatio: 2

                        active: progressBarToolTip.visible
                                && GeneralSettings.showPreviewThumbnail
                                && previewMpvLoader.file !== ""
                                && root.m_mpv.playbackState !== MpvItem.PlaybackState.Stopped
                                && root.m_mpv.isLocalFile
                                && root.m_mpv.isVideo
                        visible: active
                        asynchronous: true
                        sourceComponent: MpvPreview {
                            id: mpvPreview
                            accuratePreview: GeneralSettings.accuratePreviewThumbnail
                            position: previewMpvLoader.position
                            file: previewMpvLoader.file

                            onAspectRatioChanged: previewMpvLoader.aspectRatio = aspectRatio || 2
                        }

                        Layout.preferredWidth: Math.max(64, Math.min(GeneralSettings.previewThumbnailWidth, root.m_mpv.width - 32))
                        Layout.preferredHeight: Math.ceil(Layout.preferredWidth / previewMpvLoader.aspectRatio)
                        Layout.alignment: Qt.AlignCenter
                    }

                    Label {
                        id: timePositionLabel

                        elide: Text.ElideRight
                        color: "#f4f4f5"
                        Layout.alignment: Qt.AlignCenter
                        Layout.maximumWidth: GeneralSettings.previewThumbnailWidth
                    }
                }
            }

            MouseArea {
                id: progressBarMouseArea

                anchors.fill: parent
                anchors.topMargin: -9
                anchors.bottomMargin: -9
                hoverEnabled: true
                acceptedButtons: Qt.MiddleButton | Qt.RightButton

                onClicked: function(mouse) {
                    if (mouse.button === Qt.MiddleButton) {
                        if (!GeneralSettings.showChapterMarkers) {
                            return
                        }

                        const time = mouseX / progressBarBG.width * slider.to
                        const chapters = root.m_mpv.getProperty(MpvProperties.ChapterList)
                        const nextChapter = chapters.findIndex(chapter => chapter.time > time)
                        root.m_mpv.chapter = nextChapter
                    }
                    if (mouse.button === Qt.RightButton && root.m_mpv.chaptersModel.rowCount > 0) {
                        chaptersPopup.x = mouseX - chaptersPopup.width * 0.5
                        chaptersPopup.open()
                    }
                }

                onEntered: slider.updateTooltip()

                onMouseXChanged: {
                    slider.updateTooltip()
                }

                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0) {
                        HarunaApp.actions.seekForwardMediumAction.trigger()
                    } else if (wheel.angleDelta.y) {
                        HarunaApp.actions.seekBackwardMediumAction.trigger()
                    }
                }
            }
        }

        onToChanged: {
            value = root.m_mpv.position
            slider.updateTooltip()
        }

        onMoved: {
            if (!pressed) {
                return
            }

            root.m_mpv.commandAsync(["seek", slider.value, "absolute"])
            const chapterTitle = root.m_mpv.chaptersModel.titleAtPosition(slider.value)
            const formattedTime = MiscUtils.formatTime(slider.value)
            timePositionLabel.text = chapterTitle === ""
                    ? formattedTime
                    :`${formattedTime} - ${chapterTitle}`

            slider.requestPreview(slider.value)
        }

        onPressedChanged: {
            seekStarted = pressed
            if (pressed) {
                slider.prePressPause = root.m_mpv.getProperty(MpvProperties.Pause)
                root.m_mpv.setPropertyBlocking(MpvProperties.Pause, true)
            } else {
                root.m_mpv.setPropertyBlocking(MpvProperties.Pause, slider.prePressPause)
            }
        }

        // create markers for the chapters
        Repeater {
            id: chaptersInstantiator

            model: root.showChapterMarkers
                   ? root.m_mpv.chaptersModel
                   : 0
            delegate: Rectangle {
                required property double startTime

                visible: root.m_mpv.duration > 0
                x: root.m_mpv.duration <= 0 ? 0 : slider.mirrored
                   ? progressBarBG.width - (startTime / root.m_mpv.duration * progressBarBG.width)
                   : startTime / root.m_mpv.duration * progressBarBG.width
                y: progressBarBG.y
                height: progressBarBG.height
                width: 1
                color: "#b3ffffff"
            }
        }

        Popup {
            id: chaptersPopup

            property int itemHeight
            property int itemBiggestWidth: 1
            property int maxWidth: Math.max(Kirigami.Units.gridUnit * 40, root.width * 0.8)

            y: -height - slider.height
            z: 20
            width: Math.min(itemBiggestWidth, maxWidth)
            height: Math.min(root.m_mpv.height, listViewContainer.contentHeight)
            modal: true
            padding: 0
            onOpened: {
                listView.positionViewAtIndex(root.m_mpv.chapter, ListView.Beginning)
            }

            ScrollView {
                id: listViewContainer

                anchors.fill: parent

                ListView {
                    id: listView

                    clip: true
                    footerPositioning: ListView.OverlayFooter
                    model: root.m_mpv.chaptersModel
                    reuseItems: true
                    delegate: RadioDelegate {
                        id: menuitem

                        required property int index
                        required property string title
                        required property double startTime

                        text: `${MiscUtils.formatTime(menuitem.startTime)} - ${menuitem.title}`
                        checked: menuitem.index === root.m_mpv.chapter
                        width: ListView.view.width
                        onClicked: {
                            chaptersPopup.close()
                            root.m_mpv.chapter = menuitem.index
                        }
                        onImplicitWidthChanged: {
                            let popup = chaptersPopup
                            popup.itemBiggestWidth = Math.max(implicitWidth + 50, popup.width)
                            popup.itemHeight = height
                        }
                    }
                    footer: ToolBar {
                        z: 100
                        width: parent.width
                        height: 26
                        CheckBox {
                            id: skipChaptersCheckBox

                            anchors.verticalCenter: parent.verticalCenter
                            text: KI18n.i18nc("@action:inmenu", "Skip Chapters")
                            checked: PlaybackSettings.skipChapters
                            onCheckedChanged: {
                                PlaybackSettings.skipChapters = checked
                                PlaybackSettings.save()
                            }

                            ToolTip {
                                text: KI18n.i18nc("@info:tooltip", "Automatically skips chapters containing certain words/characters.\nCheck “Playback” settings for more details.")
                                delay: HarunaApp.isAltKeyPressed ? 0 : Kirigami.Units.toolTipDelay
                                visible: skipChaptersCheckBox.hovered
                                         && (GeneralSettings.showExplanatoryToolTips || HarunaApp.isAltKeyPressed)
                            }
                        }
                    }
                }
            }
        }

        Connections {
            target: root.m_mpv
            function onFileStarted() {
                previewSeekTimer.stop()
                slider.requestedPreviewPosition = 0
                previewMpvLoader.position = 0
                loopIndicator.startPosition = -1
                loopIndicator.endPosition = -1
                previewMpvLoader.file = root.m_mpv.currentUrl
            }
            function onPositionChanged() {
                if (!slider.seekStarted) {
                    slider.value = root.m_mpv.position
                }
            }
        }
    }
}
