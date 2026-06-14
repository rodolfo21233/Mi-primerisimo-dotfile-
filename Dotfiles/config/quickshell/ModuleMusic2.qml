import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import "." 

PanelWindow {
    id: toplevel
    color: "transparent"
    
    anchors {
        bottom: false
        left: false
        right: false
        top: true
    }
    exclusionMode: ExclusionMode.Ignore

 
    property var activePlayer: {
        if (Mpris.players && Mpris.players.values.length > 0) {
            return Mpris.players.values[0]
        }
        return null
    }

    property real currentPosition: activePlayer ? activePlayer.position : 0

    
    Connections {
        target: activePlayer
        function onPositionChanged() { toplevel.currentPosition = activePlayer.position }
        function onPlaybackStatusChanged() { toplevel.currentPosition = activePlayer.position }
    }


    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        running: true
        
        onTriggered: {
            
            toplevel.activePlayer = (Mpris.players && Mpris.players.values.length > 0) 
                                    ? Mpris.players.values[0] 
                                    : null
            
            // Si el reproductor existe, actualizamos nuestra variable local manualmente
            if (toplevel.activePlayer) {
                toplevel.currentPosition = toplevel.activePlayer.position
            }
        }
    }

    function formatTime(totalSeconds) {
        if (!totalSeconds || isNaN(totalSeconds)) return "0:00"
        let min = Math.floor(totalSeconds / 60)
        let sec = Math.floor(totalSeconds % 60)
        return min + ":" + sec.toString().padStart(2, '0')
    }
     function abrirMenu2() {
            timerabrir.start()
    }
    
    function solicitarCierre2() {
            timerCierre2.start()
    }

    Timer {
            id: timerCierre2
            interval: 200
            onTriggered: popup2.open2 = false
    }
     Timer {
            id: timerabrir
            interval: 100
            onTriggered: popup2.open2 = true
    }

    

    PopupWindow {
        id: popup2
        property bool open2: false
        anchor.window: toplevel
        anchor.rect.x: -190
        anchor.rect.y: 1
        
        width: 500
        implicitHeight: open2 ? 250 : 1
        color: "transparent"
        visible: open2 || implicitHeight > 1

          Behavior on implicitHeight { 
                NumberAnimation { 
                    duration: 300
                    easing.type: Easing.OutCirc
                } 
            }
       

        Rectangle {
            id: prime
            anchors.fill: parent
            radius: 12
            color: "#ffffff"

             HoverHandler {
                    id: menuHover
                    onHoveredChanged: {
                        if (hovered) {
                            timerCierre2.stop()
                        } else {
                            timerCierre2.start()
                        }
                    }
                }

               Rectangle {
                    id: coverImage
                    x: 15
                    y: 15
                    width: 220
                    height: 220
                    radius: 25
                    clip: true

                    layer.enabled: true

                    border.color: "#ff0000"
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        

                        source: activePlayer && activePlayer.trackArtUrl !== ""
                                ? activePlayer.trackArtUrl
                                : "file:///ruta/a/imagen-defecto.png"

                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                }
                  
           
            Text {
                id: titleText
                text: activePlayer ? activePlayer.trackTitle  : "No player"
                
                
                anchors.left: coverImage.right
                anchors.leftMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 30
                anchors.right: parent.right 
                anchors.rightMargin: 15
                
                color: "black" 
                font.pixelSize: 20
                font.bold: true
                
                wrapMode: Text.WordWrap 
                elide: Text.ElideRight
            }
               Text {
                id: titleText2
                text: (activePlayer.trackArtist || "Unknown Artist")
                
                anchors.left: coverImage.right
                anchors.leftMargin: 20

                anchors.top: titleText.bottom
                anchors.topMargin: 1

                color: "gray"
                font.pixelSize: 16
                
                
                wrapMode: Text.WordWrap 
                elide: Text.ElideRight
            }

            Text {
                id: artistText
                text: activePlayer && activePlayer.trackArtists.length > 0 ? activePlayer.trackArtists.join(", ") : ""
                
                anchors.left: coverImage.right
                anchors.leftMargin: 20
                anchors.top: titleText.bottom
                anchors.topMargin: 5
                anchors.right: parent.right 
                anchors.rightMargin: 15
                
                color: "gray" 
                font.pixelSize: 14
                
                wrapMode: Text.WordWrap 
                elide: Text.ElideRight
            }

            Item {
                id: progressContainer
                anchors.left: coverImage.right
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                
                anchors.leftMargin: 20
                anchors.rightMargin: 15
                anchors.bottomMargin: 30
                height: 20

                Text {
                    id: positionText
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: formatTime(toplevel.currentPosition)
                    color: "gray"
                    font.pixelSize: 12
                }

                Rectangle {
                    id: progressBarBackground
                    anchors.left: positionText.right
                    anchors.right: lengthText.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    height: 6
                    radius: 3
                    color: "#e0e0e0"

                    Rectangle {
                        id: progressFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        radius: 3
                        color: "black" 
                        
                        width: (activePlayer && activePlayer.length > 0) 
                               ? Math.max(0, Math.min(toplevel.currentPosition / activePlayer.length, 1)) * progressBarBackground.width 
                               : 0

                        Behavior on width {
                            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                        }
                    }
                 }

                Text {
                    id: lengthText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: activePlayer && activePlayer.length > 0 ? formatTime(activePlayer.length) : "0:00"
                    color: "gray"
                    font.pixelSize: 12
                }
            }
                Rectangle{
                    id: playbutton
                    property bool pause: false
                    color: "#b3b3b3"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 45
                    anchors.verticalCenterOffset: 30
                    implicitHeight: 40
                    implicitWidth: 50
                    radius: 20
                    Text{
                         text: activePlayer && activePlayer.isPlaying
                        ? ""
                        : ""
                        anchors.centerIn: parent
                        font.pixelSize: 20
                    }
                 MouseArea {
                    id: mouse
                    anchors.fill: parent

                    onClicked: {
                        if (activePlayer) {
                            activePlayer.togglePlaying()
                           
                        }
                    } 
                
                    Rectangle{
                    color: "#b3b3b3"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 60
                    anchors.verticalCenterOffset: 0
                    implicitHeight: 40
                    implicitWidth: 50
                    radius: 20
                    Text{
                        text: "󰒭"
                        anchors.centerIn: parent
                        font.pixelSize: 20
                    }
                 MouseArea {
                    id: mouse2
                    anchors.fill: parent

                    onClicked: {
                        if (activePlayer) {
                            activePlayer.next()
                        }
                          
                            }    
                        }   
                    }
                }   
            }
        }

 }     }  