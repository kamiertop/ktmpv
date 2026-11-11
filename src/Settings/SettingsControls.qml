/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls.Basic as Basic
import org.kde.kirigami as Kirigami

QtObject {
    component Surface: Rectangle {
        property bool emphasized: false
        property bool focused: false

        radius: 8
        color: Qt.alpha(Kirigami.Theme.textColor, emphasized ? 0.12 : 0.055)
        border.width: focused ? 2 : 1
        border.color: focused ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.10)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    component Toggle: Basic.CheckBox {
        id: control

        hoverEnabled: true
        implicitHeight: Math.max(32, implicitContentHeight + topPadding + bottomPadding)
        spacing: 10
        padding: 4
        palette.windowText: Kirigami.Theme.textColor
        palette.text: Kirigami.Theme.textColor

        indicator: Rectangle {
            x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
            y: (control.height - height) / 2
            implicitWidth: 34
            implicitHeight: 19
            radius: height / 2
            opacity: control.enabled ? 1 : 0.55
            color: control.checked ? Kirigami.Theme.highlightColor
                                   : Qt.alpha(Kirigami.Theme.textColor, control.hovered ? 0.31 : 0.22)
            border.width: control.visualFocus ? 2 : 0
            border.color: Kirigami.Theme.textColor
            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                width: 13
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: control.checked !== control.mirrored ? parent.width - width - 3 : 3
                color: control.checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.backgroundColor
                Behavior on x { NumberAnimation { duration: 120 } }
            }
        }
    }

    component SelectOption: Basic.ItemDelegate {
        id: option

        property bool selected: false

        width: ListView.view?.width ?? implicitWidth
        implicitHeight: 32
        padding: 8
        leftPadding: 12
        rightPadding: 12
        hoverEnabled: true
        palette.text: Kirigami.Theme.textColor
        palette.highlightedText: Kirigami.Theme.textColor
        font.weight: selected ? Font.DemiBold : Font.Normal

        background: Item {
            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: 6
                color: Qt.alpha(Kirigami.Theme.textColor,
                                option.down ? 0.23 : option.highlighted || option.hovered ? 0.16
                                : option.selected ? 0.11 : 0)
            }
        }
    }

    component Select: Basic.ComboBox {
        id: control

        hoverEnabled: true
        palette.buttonText: Kirigami.Theme.textColor
        palette.text: Kirigami.Theme.textColor
        palette.base: Kirigami.Theme.backgroundColor
        palette.window: Kirigami.Theme.backgroundColor
        palette.mid: Qt.alpha(Kirigami.Theme.textColor, 0.14)
        palette.dark: Kirigami.Theme.textColor
        palette.highlight: Kirigami.Theme.highlightColor
        palette.highlightedText: Kirigami.Theme.highlightedTextColor
        delegate: SelectOption {
            required property int index

            text: control.textAt(index)
            selected: control.currentIndex === index
            highlighted: control.highlightedIndex === index
        }
        background: Surface {
            implicitWidth: 140
            implicitHeight: 34
            emphasized: control.hovered || control.down
            focused: control.visualFocus
        }
    }

    component NumberField: Basic.SpinBox {
        id: control

        palette.button: Qt.alpha(Kirigami.Theme.textColor, 0.045)
        palette.mid: Qt.alpha(Kirigami.Theme.textColor, 0.14)
        palette.buttonText: Kirigami.Theme.textColor
        palette.text: Kirigami.Theme.textColor
        palette.highlight: Kirigami.Theme.highlightColor
        palette.highlightedText: Kirigami.Theme.highlightedTextColor
        implicitHeight: 34
        background: Surface {
            implicitWidth: 124
            focused: control.visualFocus
        }
    }

    component ActionButton: Basic.Button {
        id: control

        hoverEnabled: true
        palette.buttonText: Kirigami.Theme.textColor
        background: Surface {
            implicitWidth: 68
            implicitHeight: 34
            emphasized: control.hovered || control.down
            focused: control.visualFocus
        }
    }

    component SectionTitle: Basic.Label {
        topPadding: 14
        bottomPadding: 7
        font.weight: Font.DemiBold
        font.pixelSize: 15
        color: Kirigami.Theme.textColor

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
        }
    }
}
