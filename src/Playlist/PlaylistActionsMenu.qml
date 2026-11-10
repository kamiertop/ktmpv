/*
 * SPDX-FileCopyrightText: 2026 Haruna contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Menu {
    id: root

    required property list<QtObject> actions
    property Component submenuComponent

    Component {
        id: menuItem
        MenuItem {
            autoExclusive: (action as Kirigami.Action)?.autoExclusive ?? false
        }
    }
    Component { id: separatorItem; MenuSeparator {} }

    Instantiator {
        active: root.visible
        model: root.actions
        delegate: QtObject {
            id: entry
            required property QtObject modelData
            property QtObject menuEntry: null
            readonly property bool isSubmenu: (modelData as Kirigami.Action).children.length > 0

            Component.onCompleted: {
                const action = modelData as Kirigami.Action
                if (isSubmenu) {
                    menuEntry = root.submenuComponent.createObject(null, {
                        title: action.text,
                        icon: action.icon,
                        actions: action.children,
                        submenuComponent: root.submenuComponent,
                    })
                    root.addMenu(menuEntry)
                } else if (action.separator) {
                    menuEntry = separatorItem.createObject(null)
                    root.addItem(menuEntry)
                } else {
                    menuEntry = menuItem.createObject(null, { action: action })
                    root.addItem(menuEntry)
                }
            }
            Component.onDestruction: {
                if (!menuEntry) {
                    return
                }
                if (isSubmenu) {
                    root.removeMenu(menuEntry)
                } else {
                    root.removeItem(menuEntry)
                }
                menuEntry.destroy()
            }
        }
    }
}
