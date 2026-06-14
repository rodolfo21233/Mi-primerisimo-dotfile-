import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Controls
import Quickshell.Wayland
import "."
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower



PanelWindow {

    property var activePlayer: {
        if (Mpris.players && Mpris.players.values.length > 0) {
            return Mpris.players.values[0]
        }
        return null
    }

    id: toplevel
    color: "transparent"

    anchors {
        bottom: false
        left: false
        right: false
        top: true
    }

    exclusionMode: ExclusionMode.Ignore

    property int targetX: 0
    property int targetY: 0

    Timer {
        id: timerCierre
        interval: 100
        onTriggered: popup.open = false
    }

    function abrirMenu(posX, posY) {
        targetX = posX
        targetY = posY
        timerCierre.stop()
        popup.open = true
    }

    function solicitarCierre() {
        timerCierre.start()
    }

    Process {
        id: setProfile
    }

    Process {
        id: wifiProcess
        command: ["sh", "-c",
            "nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2"
        ]

        running: true

        stdout: SplitParser {
            onRead: data => {
                wifiLabel.text = data.trim()
            }
        }
    }

    PopupWindow {
        id: popup

        property bool open: false
        property string currentProfile: "balanced"

        anchor.window: toplevel
        anchor.rect.x: targetX - 1000
        anchor.rect.y: targetY

        width: 400
        implicitHeight: open ? 500 : 1

        color: "transparent"
        visible: open || implicitHeight > 1

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCirc
            }
        }

        Rectangle {
            anchors.fill: parent

            bottomLeftRadius: 8
            bottomRightRadius: 8
            color: "#ffffff"

            HoverHandler {
                id: menuHover

                onHoveredChanged: {
                    if (hovered) {
                        timerCierre.stop()
                    } else {
                        timerCierre.start()
                    }
                }
            }

            Text {
                id: clock

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -80
                anchors.topMargin: 25
                

                text: Qt.formatTime(new Date(), "HH:mm")

                font.pixelSize: 42
                font.bold: true

                color: "#111827"
            }

             Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 60
                anchors.topMargin: 25
                
                
             text: UPower.displayDevice.ready
              ? Math.round(UPower.displayDevice.percentage * 100) + "%"
              : "N/A"
              font.pixelSize: 42
              font.bold: true
              color: "#111827"
            }
            
            Text{
                id: wifiLabel
                text: wifiLabel
            }
            
           
            
           
                Slider {
                    id: volumeSlider
                    anchors.centerIn:parent
                    anchors.verticalCenterOffset: -120
                   
                    width: 280
                    from: 0
                    to: 1
                    
                    Process {
                        id: setVolume
                    }

                    Process {
                        id: getVolume
                        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"]
                         stdout: StdioCollector {
                            onStreamFinished: {
                                let vol = parseFloat(text.trim())

                                if (!isNaN(vol))
                                    volumeSlider.value = vol
                            }
                        }
                    }

                    onMoved: {
                        setVolume.command = [
                            "wpctl",
                            "set-volume",
                            "@DEFAULT_AUDIO_SINK@",
                            value.toString()
                        ]
                        setVolume.running = true
                    }

                    Timer {
                        interval: 500
                        running: true
                        repeat: true

                        onTriggered: {
                            getVolume.running = true
                        }
                    }

                    background: Rectangle {
                        implicitWidth: 250
                        implicitHeight: 30
                        radius: height / 2
                        color: "#5c5c5c"

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: "#949494"
                        }
                    }

                    handle: Rectangle {
                        width: 1
                        height: 1
                        color: "transparent"
                    }


                Timer {
                    interval: 100
                    running: true
                    repeat: true

                    onTriggered: {
                        getVolume.running = true
                    }
                }
                Text{
                    anchors.centerIn:parent
                    anchors.horizontalCenterOffset: -120
                    text: ""
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                }
            }

            RowLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 50

                Rectangle {
                    radius: 10
                    width: 80
                    height: 60

                    color: popup.currentProfile === "performance"
                        ? "#2563eb"
                        : mouse3.containsMouse
                            ? "#9ca3af"
                            : "#4b5563"

                    scale: mouse3.containsMouse ? 1.1 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    MouseArea {
                        id: mouse3

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            popup.currentProfile = "performance"
                            setProfile.command = ["powerprofilesctl", "set", "performance"]
                            setProfile.running = true
                        }
                    }
                }

                Rectangle {
                    radius: 10
                    width: 80
                    height: 60

                    color: popup.currentProfile === "balanced"
                        ? "#f59e0b"
                        : mouse2.containsMouse
                            ? "#9ca3af"
                            : "#4b5563"

                    scale: mouse2.containsMouse ? 1.1 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    MouseArea {
                        id: mouse2

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            popup.currentProfile = "balanced"
                            setProfile.command = ["powerprofilesctl", "set", "balanced"]
                            setProfile.running = true
                        }
                    }
                }

                Rectangle {
                    radius: 10
                    width: 80
                    height: 60

                    color: popup.currentProfile === "power-saver"
                        ? "#22c55e"
                        : mouse.containsMouse
                            ? "#9ca3af"
                            : "#4b5563"

                    scale: mouse.containsMouse ? 1.1 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    MouseArea {
                        id: mouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            popup.currentProfile = "power-saver"
                            setProfile.command = ["powerprofilesctl", "set", "power-saver"]
                            setProfile.running = true
                        }
                    }
                }
            }
        }
    }
}