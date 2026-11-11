/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.ki18n
import org.kde.kirigami as Kirigami

import org.kde.haruna
import org.kde.haruna.settings
import org.kde.haruna.utilities

SettingsBasePage {
    id: root

    GridLayout {
        id: content

        columns: 2
        columnSpacing: 16
        rowSpacing: 10

        Label {
            text: KI18n.i18nc("@label:spinbox", "Maximum recent files")
            Layout.alignment: Qt.AlignRight
        }

        RowLayout {
            SettingsControls.NumberField {
                id: maxRecentFiles

                from: 0
                to: 100
                value: GeneralSettings.maxRecentFiles
                onValueModified: {
                    GeneralSettings.maxRecentFiles = maxRecentFiles.value
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                toolTipText: KI18n.i18nc("@info:tooltip", "The number of recent files to display. Enter 0 (zero) to disable.<br>" +
                            "Every opened file is stored.<br>Bold entries are files opened from the open file/url " +
                            "actions and from external apps (command line, file manager, drag and drop etc.).")
                toolTipWidth: 450

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Item { Layout.preferredWidth: 1 }

        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Allow only one instance")
                checked: GeneralSettings.useSingleInstance
                onClicked: {
                    GeneralSettings.useSingleInstance = checked
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                toolTipText: KI18n.i18nc("@info:tooltip", "Trying to open another Haruna instance will do nothing.<br>"+
                                   "Trying to open another file with Haruna will open the file in the running instance.")

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Item { Layout.preferredWidth: 1 }

        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Add file to playlist")
                checked: GeneralSettings.appendVideoToSingleInstance
                enabled: GeneralSettings.useSingleInstance
                onClicked: {
                    GeneralSettings.appendVideoToSingleInstance = checked
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                toolTipText: KI18n.i18nc("@info:tooltip", "File will be added to the end of the playlist.")

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Item { Layout.preferredWidth: 1 }

        SettingsControls.Toggle {
            text: KI18n.i18nc("@option:check", "Play new file")
            checked: GeneralSettings.playNewFileInSingleInstance
            enabled: GeneralSettings.useSingleInstance && GeneralSettings.appendVideoToSingleInstance
            onClicked: {
                GeneralSettings.playNewFileInSingleInstance = checked
                GeneralSettings.save()
            }
        }


        SettingsControls.SectionTitle {
            text: KI18n.i18nc("@title", "Interface")
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }

        Label {
            text: KI18n.i18nc("@label:spinbox", "Preview thumbnail")
            Layout.alignment: Qt.AlignRight
        }

        SettingsControls.Toggle {
            text: KI18n.i18nc("@option:check", "Show preview thumbnail")
            checked: GeneralSettings.showPreviewThumbnail
            onClicked: {
                GeneralSettings.showPreviewThumbnail = checked
                GeneralSettings.save()
            }

            ToolTip.text: KI18n.i18nc("@info:tooltip", "Shows a preview while hovering the seek/progress bar.")
            ToolTip.visible: hovered
            ToolTip.delay: 700
        }

        Item { Layout.preferredWidth: 1 }

        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Use accurate preview")
                checked: GeneralSettings.accuratePreviewThumbnail
                enabled: GeneralSettings.showPreviewThumbnail
                onClicked: {
                    GeneralSettings.accuratePreviewThumbnail = checked
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                toolTipText: KI18n.i18nc("@info:tooltip", "Generating an accurate preview is slow")
                icon.color: Kirigami.Theme.negativeTextColor

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Label {
            text: KI18n.i18nc("@label:spinbox", "Thumbnail width")
            Layout.alignment: Qt.AlignRight
        }

        SettingsControls.NumberField {
            id: previewThumbnailWidth

            from: 100
            to: 10000
            value: GeneralSettings.previewThumbnailWidth
            enabled: GeneralSettings.showPreviewThumbnail
            onValueModified: {
                GeneralSettings.previewThumbnailWidth = previewThumbnailWidth.value
                GeneralSettings.save()
            }
        }

        Label {
            text: KI18n.i18nc("@label", "Window")
            Layout.alignment: Qt.AlignRight
        }

        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Resize to fit video")
                checked: GeneralSettings.resizeWindowToVideo
                enabled: !SystemUtils.isPlatformWayland()
                onClicked: {
                    GeneralSettings.resizeWindowToVideo = checked
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                toolTipText: SystemUtils.isPlatformWayland()
                             ? KI18n.i18nc("@info:tooltip","Not supported on Wayland.")
                             : KI18n.i18nc("@info:tooltip", "The window is resized according to the video resolution.<br>" +
                                     "The maximum size is not constrained, this is left to the operating system.")

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Item { Layout.preferredWidth: 1 }
        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Start in fullscreen mode")
                checked: GeneralSettings.fullscreenOnStartUp
                onClicked: {
                    GeneralSettings.fullscreenOnStartUp = checked
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                toolTipText: KI18n.i18nc("@info:tooltip", "Enter fullscreen mode when the application starts.<br>" +
                                   "This takes precedence over Resize to fit video, and Remember window size and position settings.")

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Item { Layout.preferredWidth: 1 }

        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Remember window size and position")
                checked: GeneralSettings.rememberWindowGeometry
                enabled: !GeneralSettings.resizeWindowToVideo
                onClicked: {
                    GeneralSettings.rememberWindowGeometry = checked
                    GeneralSettings.save()
                }
            }

            ToolTipButton {
                readonly property
                string waylandMessage: SystemUtils.isPlatformWayland()
                                       ? KI18n.i18nc("@info:tooltip extra wayland info for the “Remember window size and position” setting",
                                               "<b>Restoring position is not supported on Wayland.</b><br><br>")
                                       : ""
                toolTipText: KI18n.i18nc("@info:tooltip", "Changes to the window’s size and position "
                            +"are saved and used for newly opened windows.<br><br>"
                            +"%1The “Resize to fit video” setting takes precedence.", waylandMessage)
                icon.color: SystemUtils.isPlatformWayland() ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor

                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }
        }

        Item { Layout.preferredWidth: 1 }

        SettingsControls.Toggle {
            text: KI18n.i18nc("@option:check", "Show menubar")
            checked: GeneralSettings.showMenuBar
            onClicked: {
                GeneralSettings.showMenuBar = checked
                GeneralSettings.save()
            }
        }

        Item { Layout.preferredWidth: 1 }

        SettingsControls.Toggle {
            text: KI18n.i18nc("@option:check", "Show toolbar")
            checked: GeneralSettings.showHeader
            onClicked: {
                GeneralSettings.showHeader = checked
                GeneralSettings.save()
            }
        }

        Item { Layout.preferredWidth: 1 }

        RowLayout {
            SettingsControls.Toggle {
                text: KI18n.i18nc("@option:check", "Show explanatory tooltips")
                checked: GeneralSettings.showExplanatoryToolTips
                onClicked: {
                    GeneralSettings.showExplanatoryToolTips = checked
                    GeneralSettings.save()
                }
            }
            ToolTipButton {
                toolTipText: KI18n.i18nc("@info:tooltip",
                                         "Only affects tooltips that explain how something works or what it does.<br><br>"+
                                         "Tooltips that show extra information will not be disabled " +
                                         "(e.g. the seekbar tooltip showing the time at the mouse position, " +
                                         "tooltips for truncated text).")
            }
        }

        Item { Layout.preferredWidth: 1 }

        SettingsControls.Toggle {
            text: KI18n.i18nc("@option:check", "Show chapter markers")
            checked: GeneralSettings.showChapterMarkers
            onClicked: {
                GeneralSettings.showChapterMarkers = checked
                GeneralSettings.save()
            }
        }

        Item { Layout.preferredWidth: 1 }

        SettingsControls.Toggle {
            text: KI18n.i18nc("@option:check", "Show progress on taskbar icon")
            checked: GeneralSettings.showTaskbarProgress
            onClicked: {
                GeneralSettings.showTaskbarProgress = checked
                GeneralSettings.save()
            }
        }

        Label {
            text: KI18n.i18nc("@label:listbox", "Color scheme")
            Layout.alignment: Qt.AlignRight
        }

        SettingsControls.Select {
            id: colorThemeSwitcher

            textRole: "display"
            model: HarunaApp.colorSchemesModel
            delegate: SettingsControls.SelectOption {
                id: delegate

                required property int index
                required property var model

                selected: colorThemeSwitcher.currentIndex === index
                highlighted: colorThemeSwitcher.highlightedIndex === index
                contentItem: RowLayout {
                    Kirigami.Icon {
                        source: delegate.model.decoration
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    }
                    Label {
                        text: delegate.model.display
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                    }
                }
            }

            onActivated: function(index) {
                GeneralSettings.colorScheme = colorThemeSwitcher.textAt(index)
                GeneralSettings.save()
            }

            Component.onCompleted: {
                currentIndex = find(GeneralSettings.colorScheme)
                if (currentIndex === -1) {
                    currentIndex = find("Default")
                }
            }
        }

        Label {
            text: KI18n.i18nc("@label:listbox", "GUI style")
            Layout.alignment: Qt.AlignRight
        }

        SettingsControls.Select {
            id: guiStyleComboBox

            textRole: "text"
            valueRole: "value"
            model: ListModel {
                id: stylesModel
            }

            onActivated: function(index) {
                GeneralSettings.guiStyle = model.get(index).value
                HarunaApp.setGuiStyle(GeneralSettings.guiStyle)
                // some themes can cause a crash
                // the timer prevents saving the crashing theme,
                // which would cause the app to crash on startup
                saveGuiStyleTimer.start()
            }

            Timer {
                id: saveGuiStyleTimer

                interval: 1000
                running: false
                repeat: false
                onTriggered: GeneralSettings.save()
            }

            Component.onCompleted: {
                const defaultStyle = {
                    text: KI18n.i18nc("@item:listbox default GUI style", "Default"),
                    value: "Default"
                }
                stylesModel.append(defaultStyle)


                // populate the model with the available styles
                const styles = HarunaApp.availableGuiStyles()
                for (let i = 0; i < styles.length; ++i) {
                    const style = {
                        text: styles[i],
                        value: styles[i]
                    }
                    stylesModel.append(style)
                }

                // set the saved style as the current item in the combo box
                currentIndex = indexOfValue(GeneralSettings.guiStyle)
            }
        }

        Item {
            Layout.preferredWidth: Kirigami.Units.gridUnit
            Layout.preferredHeight: Kirigami.Units.gridUnit
        }
    }
}
