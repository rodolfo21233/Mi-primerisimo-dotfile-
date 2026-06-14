import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Wayland

/*
 * AppLauncher.qml — Quickshell 0.3.0 compatible
 *
 * State is on the root. Search field mirrors to a property. ListView binds
 * to the filtered list. One direction of data flow = no feedback loops.
 *
 * Icon: .desktop Icon= is a name (e.g. "firefox"). Qt6's Image does NOT
 * resolve theme names; we build candidate paths and try the most likely
 * ones. First one that Image.status === Ready wins.
 *
 * Launch: DesktopEntry.command is the parsed exec line (QStringList).
 * We use Quickshell.execDetached() — the simplest spawner. No fork, no
 * process tracking. The launcher just closes itself.
 *
 * Open/close: controlled by abrirMenu() / solicitarCierre(). Bind a
 * GlobalShortcut in shell.qml to toggle it.
 *
 * Animation: smooth slide from below + fade. showProgress drives
 * translateY (off-screen down → on-screen), scale, and opacity in one
 * pass via NumberAnimation on the root.
 *
 * Command mode: typing ">" as the first character switches from apps to
 * a built-in command list (wallpaper, calculator, …). Selecting a

 */

PanelWindow {
    id: toplevel
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: 500
    implicitHeight: open ? 520 : 1
    anchors {
        bottom: false
        left: false
        right: false
        top: false
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ---- state ----
    property bool open: false
    visible: open

    property string query: ""
    property int selectedIndex: 0

   
    // 0 = hidden (translated down, faded out, slightly scaled down)
    // 1 = visible (in place, full opacity, normal scale)
    property real showProgress: 0
    Behavior on showProgress {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }
 

    // height eases too so the click-outside area collapses cleanly
    Behavior on implicitHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // ---- command mode ----
    // Built-in command list. Each entry: { name, description, icon, command }.
    // No exec wiring yet — selecting a command just closes the launcher.
    property var commandList: [
        { name: "Wallpaper",     description: "Change desktop wallpaper",          icon: "󰸉" },
        { name: "Calculator",    description: "Open calculator",                    icon: "" },
        { name: "Color Picker",  description: "Pick a color from the screen",       icon: "" },
        { name: "Screenshot",    description: "Capture screen or region",           icon: "" },
     
    ]

    // ---- mode detection ----
    // "> " or just ">" → command mode
    readonly property bool commandMode: query.startsWith(">")

    // The actual filter input (without the leading ">")
    readonly property string commandFilter: commandMode
        ? query.substring(1).replace(/^\s+/, "").toLowerCase()
        : ""

    // ---- data ----
    function allApps() {
        return DesktopEntries.applications.values.slice()
    }

    function filteredApps() {
        if (commandMode) {
            const q = commandFilter
            if (q.length === 0) return commandList
            return commandList.filter(function(c) {
                return (c.name || "").toLowerCase().includes(q)
            })
        }
        const q = query.toLowerCase().trim()
        const all = allApps()
        if (q.length === 0) return all
        return all.filter(function(a) {
            return (a.name || "").toLowerCase().includes(q)
        })
    }

    function currentSelection() {
        const list = filteredApps()
        if (list.length === 0) return null
        if (selectedIndex >= list.length) selectedIndex = 0
        if (selectedIndex < 0) selectedIndex = 0
        return list[selectedIndex]
    }

    function launchSelected() {                                                                           
        if (commandMode) {                                                                                
            const cmd = currentSelection()                                                                
            if (!cmd) {                                                                                   
                solicitarCierre()                                                                         
                return                                                                                    
            }                                                                                             
            switch (cmd.name) {                                                                           
                case "Wallpaper":                                                                         
                    Quickshell.execDetached(["sh", "-c", "swww img ~/Pictures/wallpaper.jpg"])            
                    break                                                                                 
                case "Calculator":                                                                        
                    Quickshell.execDetached(["galculator"])                                               
                    break                                                                                 
                case "Color Picker":                                                                      
                    Quickshell.execDetached(["hyprpicker", "-a"])                                         
                    break                                                                                 
                case "Screenshot":                                                                        
                    Quickshell.execDetached(["sh", "-c", "grim -g \"$(slurp)\" - | wl-copy"])             
                    break                                                                                 
                case "Lock Screen":                                                                       
                    Quickshell.execDetached(["loginctl", "lock-session"])                                 
                    break                                                                                 
                case "Reload Bar":                                                                        
                    Quickshell.execDetached(["sh", "-c", "killall quickshell; quickshell &"])             
                    break                                                                                 
            }                                                                                                             
            solicitarCierre()
            return
        }
        const app = currentSelection()
        if (!app) return
        if (app.command && app.command.length > 0) {
            Quickshell.execDetached(app.command)
        } else {
            Quickshell.execDetached(["gtk-launch", app.id || ""])
        }
        solicitarCierre()
    }

    // ---- show / hide ----
    Timer {
        id: timerCierre
        interval: 200
        onTriggered: toplevel.open = false
    }

    Timer {
        id: focusTimer
        interval: 120
        onTriggered: {
            searchField.forceActiveFocus()
            searchField.selectAll()
        }
    }

    function abrirMenu() {
        query = ""
        searchField.text = ""
        selectedIndex = 0
        open = true
        showProgress = 0
        showProgress = 1
        focusTimer.restart()
    }

    function solicitarCierre() {
        showProgress = 0
        timerCierre.restart()
    }

    // ---- derived animation values (slide up + fade + slight scale) ----
    // translateY: from +60px (below) to 0
    readonly property real cardOffsetY: (1 - showProgress) * 60
    readonly property real cardOpacity: showProgress
    readonly property real cardScale: 0.96 + 0.04 * showProgress

    // ---- root keyboard handler ----
    Item {
        id: rootKeys
        focus: true
        anchors.fill: parent
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Down) {
                const max = toplevel.filteredApps().length - 1
                toplevel.selectedIndex = Math.min(max, toplevel.selectedIndex + 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                toplevel.selectedIndex = Math.max(0, toplevel.selectedIndex - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                toplevel.launchSelected()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                toplevel.solicitarCierre()
                event.accepted = true
            }
        }
    }

    // ---- click outside to close ----
    // MouseArea BEHIND the card, anchored to fill the panel.
    // Since the card is on top, clicks on the card don't reach this.
    // No scrim — the panel is fully transparent so the desktop shows
    // through. Clicks on the empty area still close the launcher.
    Item {
        id: outerArea
        z: -10
        anchors.fill: parent
        MouseArea {
            anchors.fill: parent
            onClicked: toplevel.solicitarCierre()
        }
    }

    // ---- animated card container ----
    Item {
        id: card
        anchors.fill: parent
        anchors.margins: 12

        // slide up + fade + tiny scale
     
        opacity: toplevel.cardOpacity

        // card background — matches shell bar (white card on white panel)
        Rectangle {
            id: background
            anchors.fill: parent
            radius: 18
            color: "#ffffff"
            opacity: 0.98
            border.color: "#d3d4d8"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ----- search bar -----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 12
                color: "#d3d4d8"
                border.color: searchField.activeFocus ? "#ffffff" : "#9ca3af"
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    // Icon swaps based on mode
                    Text {
                        text: ""
                        color: toplevel.commandMode ? "#2563eb" : "#4b5563"
                        font.pixelSize: toplevel.commandMode ? 16 : 16
                        font.bold: toplevel.commandMode
                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true

                        background: null
                        color: "#111827"
                        placeholderText: toplevel.commandMode
                            ? "Type a command…"
                            : "Search applications…"
                        placeholderTextColor: "#6b7280"
                        font.pixelSize: 16
                        selectByMouse: true

                        onTextChanged: {
                            if (toplevel.query !== text) {
                                toplevel.query = text
                                toplevel.selectedIndex = 0
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Down) {
                                const max = toplevel.filteredApps().length - 1
                                toplevel.selectedIndex = Math.min(max, toplevel.selectedIndex + 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                toplevel.selectedIndex = Math.max(0, toplevel.selectedIndex - 1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                toplevel.launchSelected()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                toplevel.solicitarCierre()
                                event.accepted = true
                            }
                        }
                    }

                    // Mode badge on the right (only in command mode)
                  

                    Text {
                        visible: searchField.text.length > 0
                        text: "✕"
                        color: "#4b5563"
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = ""
                                toplevel.query = ""
                            }
                        }
                    }
                }
            }

            // ----- results -----
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"
                radius: 12
               
                
                clip: true

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    clip: true
                    model: toplevel.filteredApps()
                    currentIndex: toplevel.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: false

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    // Command-mode delegate (text icon + name + description)
                    Component {
                        id: commandDelegate
                        Item {
                            id: commandRoot
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 48

                            property bool isSelected: index === toplevel.selectedIndex

                            Rectangle {
                                id: cmdRowBg
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 10
                                color: commandRoot.isSelected ? "#d3d4d8" : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 4
                                    width: 3
                                    height: parent.height - 16
                                    radius: 2
                                    color: "#2563eb"
                                    opacity: commandRoot.isSelected ? 1 : 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    // Emoji icon (no .desktop entry, so we just render the glyph)
                                    Item {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: "#d3d4d8"
                                            Text {
                                                anchors.centerIn: parent
                                                text: commandRoot.modelData.icon || "•"
                                                font.pixelSize: 18
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: commandRoot.modelData.name || ""
                                        color: "#111827"
                                        font.pixelSize: 15
                                        font.bold: commandRoot.isSelected
                                        elide: Text.ElideRight
                                        Behavior on font.bold {
                                            NumberAnimation { duration: 100 }
                                        }
                                    }

                                    Text {
                                        Layout.maximumWidth: 240
                                        text: commandRoot.modelData.description || ""
                                        color: "#6b7280"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: toplevel.selectedIndex = commandRoot.index
                                    onClicked: {
                                        toplevel.selectedIndex = commandRoot.index
                                        toplevel.launchSelected()
                                    }
                                }
                            }
                        }
                    }

                    // App-mode delegate (real icons)
                    Component {
                        id: appDelegate
                        Item {
                            id: appRoot
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 48

                            property bool isSelected: index === toplevel.selectedIndex

                            Rectangle {
                                id: appRowBg
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 10
                                color: appRoot.isSelected ? "#d3d4d8" : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 4
                                    width: 3
                                    height: parent.height - 16
                                    radius: 2
                                    color: "#2563eb"
                                    opacity: appRoot.isSelected ? 1 : 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Item {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32

                                        Image {
                                            id: iconSvg
                                            anchors.fill: parent
                                            source: appRoot.modelData.icon
                                                ? "file:///usr/share/icons/hicolor/scalable/apps/" + appRoot.modelData.icon + ".svg"
                                                : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            sourceSize.width: 64
                                            sourceSize.height: 64
                                            visible: status === Image.Ready
                                        }

                                        Image {
                                            id: iconPng
                                            anchors.fill: parent
                                            source: appRoot.modelData.icon
                                                ? "file:///usr/share/icons/hicolor/256x256/apps/" + appRoot.modelData.icon + ".png"
                                                : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }

                                        Image {
                                            id: iconPix
                                            anchors.fill: parent
                                            source: appRoot.modelData.icon
                                                ? "file:///usr/share/pixmaps/" + appRoot.modelData.icon + ".svg"
                                                : ""
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 8
                                            color: "#d3d4d8"
                                            visible: iconSvg.status !== Image.Ready
                                                && iconPng.status !== Image.Ready
                                                && iconPix.status !== Image.Ready
                                            Text {
                                                anchors.centerIn: parent
                                                text: (appRoot.modelData.name || "?").charAt(0).toUpperCase()
                                                color: "#4b5563"
                                                font.pixelSize: 16
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: appRoot.modelData.name || "Unnamed"
                                        color: "#111827"
                                        font.pixelSize: 15
                                        font.bold: appRoot.isSelected
                                        elide: Text.ElideRight
                                        Behavior on font.bold {
                                            NumberAnimation { duration: 100 }
                                        }
                                    }

                                    Text {
                                        Layout.maximumWidth: 240
                                        text: appRoot.modelData.comment || appRoot.modelData.genericName || ""
                                        color: "#6b7280"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        visible: text.length > 0
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: toplevel.selectedIndex = appRoot.index
                                    onClicked: {
                                        toplevel.selectedIndex = appRoot.index
                                        toplevel.launchSelected()
                                    }
                                }
                            }
                        }
                    }

                    // Pick the right delegate for the current mode
                    delegate: toplevel.commandMode ? commandDelegate : appDelegate

                    // empty state
                    Text {
                        anchors.centerIn: parent
                        visible: toplevel.filteredApps().length === 0
                        text: toplevel.commandMode
                            ? (toplevel.commandFilter.length > 0
                                ? "No command matches \"" + toplevel.commandFilter + "\""
                                : "No commands available")
                            : (toplevel.query.length > 0
                                ? "No apps match \"" + toplevel.query + "\""
                                : "No applications found")
                        color: "#6b7280"
                        font.pixelSize: 14
                    }
                }
            }

            // footer
        }
    }

    // ---- center on screen when opened ----
    onOpenChanged: {
        if (open) {
            const screen = Quickshell.screens[0]
            if (screen) {
                this.x = screen.x + Math.round((screen.width - implicitWidth) / 2)
                this.y = screen.y + Math.round((screen.height - implicitHeight) / 2)
            }
        }
    }
}
