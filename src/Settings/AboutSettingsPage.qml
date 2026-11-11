/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.ki18n
import org.kde.kirigami as Kirigami
import org.kde.haruna

SettingsBasePage {
    id: root

    readonly property var details: HarunaApp.aboutData()

    ColumnLayout {
        width: root.availableWidth
        spacing: 12

        RowLayout {
            spacing: 16
            Kirigami.Icon {
                source: "haruna"
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
            }
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    text: root.details.displayName + " " + root.details.version
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                }
                Label {
                    text: root.details.shortDescription
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }
        Label { text: root.details.copyrightStatement }

        SettingsControls.SectionTitle {
            text: KI18n.i18nc("@title", "License")
            Layout.fillWidth: true
        }
        Repeater {
            model: root.details.licenses
            delegate: SettingsControls.ActionButton {
                required property var modelData
                text: modelData.name
                onClicked: {
                    licenseDialog.title = modelData.name
                    licenseBody.text = modelData.text
                    licenseDialog.open()
                }
            }
        }

        SettingsControls.SectionTitle {
            text: KI18n.i18nc("@title", "Contributors")
            Layout.fillWidth: true
        }
        Repeater {
            model: [...root.details.authors, ...root.details.credits, ...root.details.translators]
            delegate: Label {
                required property var modelData
                text: modelData.task ? modelData.name + " · " + modelData.task : modelData.name
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
        RowLayout {
            SettingsControls.ActionButton {
                text: KI18n.i18nc("@action:button", "Website")
                onClicked: Qt.openUrlExternally(root.details.homepage)
            }
            SettingsControls.ActionButton {
                text: KI18n.i18nc("@action:button", "Report a bug")
                onClicked: Qt.openUrlExternally(root.details.bugAddress)
            }
            SettingsControls.ActionButton {
                text: KI18n.i18nc("@action:button", "Get Involved")
                onClicked: Qt.openUrlExternally("https://community.kde.org/Get_Involved")
            }
            SettingsControls.ActionButton {
                text: KI18n.i18nc("@action:button", "Donate")
                onClicked: Qt.openUrlExternally("https://kde.org/community/donations?app=" + root.details.componentName)
            }
        }
        SettingsControls.SectionTitle {
            text: KI18n.i18nc("@title", "Libraries in use")
            Layout.fillWidth: true
        }
        Repeater {
            model: Kirigami.Settings.information
            delegate: Label {
                required property string modelData
                text: modelData
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }

    Dialog {
        id: licenseDialog

        anchors.centerIn: Overlay.overlay
        width: Math.min(640, (root.Window.window?.width ?? 680) - 40)
        height: Math.min(540, (root.Window.window?.height ?? 580) - 40)
        modal: true
        standardButtons: Dialog.Close
        contentItem: ScrollView {
            contentWidth: availableWidth
            TextArea {
                id: licenseBody
                readOnly: true
                selectByMouse: true
                wrapMode: Text.Wrap
                textFormat: TextEdit.PlainText
            }
        }
    }
}
