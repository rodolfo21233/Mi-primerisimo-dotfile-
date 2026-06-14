import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import "." 
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Io

ShellRoot {
    property string activeWindow: "Window"
    id: root
    property string appid: "quickshell"
    Module { 
        id: power
    }
    ModuleMusic2 { 
        id: music
    }

 Applauncher {                                                                                         
      id: launcher                                                                                      
  }                              
                                                                         
                                                                                                        
  GlobalShortcut {                                                                                      
      name: "launcher"                                                                                  
      onPressed: {                                                                                      
          if (launcher.open) {                                                                          
              launcher.solicitarCierre()                                                                
          } else {                                                                                      
              launcher.abrirMenu()                                                                      
          }                                                                                             
      }                                                                                                 
    }                                       
  
    GlobalShortcut {
        property bool aura2: false
        id: miShortcut
        name: "aura" 
        onPressed: {
        if (miShortcut.aura2 == false){
            music.abrirMenu2()
            miShortcut.aura2 = true
        }else{
            music.solicitarCierre2()
            miShortcut.aura2 = false
        }
            
        }
    }

    Process {
        id: windowProc
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.title // empty'"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    activeWindow = data.trim()
                }
            }
        }
        Component.onCompleted: running = true
    }
    

        Connections {
        target: Hyprland
        function onRawEvent(event) {
            windowProc.running = true
            layoutProc.running = true
        }
    }

    Scope {
        Variants {

            model: Quickshell.screens

            delegate: Component {
      
                PanelWindow {
                    required property var modelData

                    screen: modelData

                    property var player: Mpris.players.values.length > 0
                        ? Mpris.players.values[0]
                        : null

                    anchors {
                        left: true
                        right: true
                        top: true
                    }
                    

                    implicitHeight: 40
                    color: "#ffffff" 

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 20

                        Rectangle {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 30

                            color: "#ffffff"
                            radius: 12

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 2
                                spacing: 6

                                Repeater {
                                    model: 6

                                    Rectangle {
                                        Layout.preferredWidth: isActive? 25 : 18
                                        Layout.preferredHeight: 10

                                        radius: 6

                                            Behavior on Layout.preferredWidth {
                                                NumberAnimation {
                                                    duration: 300
                                                    easing.type: Easing.OutQuad
                                                }
                                            }
                                        

                                        property var ws: Hyprland.workspaces.values.find(
                                            w => w.id === index + 1
                                        )

                                        property bool isActive:
                                            Hyprland.focusedWorkspace?.id === (index + 1)

                                        color: isActive ? "#b0b0b0" : "#505050"

                                        

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: Hyprland.dispatch(
                                                "workspace " + (index + 1)
                                            )
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                                          
                                    }
                                }
                            
                        
                    Text {
                        color: "black"
                        width: parent.width - 10

                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: activeWindow
                        Layout.leftMargin: 5
                    }
                }  
            } 

                     Rectangle {
                            id: miniMpris

                            Layout.preferredWidth: 350
                            Layout.preferredHeight: expanded ? 35 : 30
                            anchors.centerIn:parent
                            property bool expanded: false
                            
                            color:  expanded ? "#ffffff" : "#d3d4d8"
                            radius: expanded ? 20 : 12

                            opacity: expanded ? 0 : 1
                            
                             Behavior on color {
                                            ColorAnimation {
                                                duration: 150
                                            }
                                        }
                               
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on Layout.preferredHeight {
                                NumberAnimation {
                                    duration: 100
                                    
                                }
                            }
                           

                            Behavior on radius {
                                NumberAnimation {
                                    duration: 250
                                }
                            }

                            HoverHandler {
                                onHoveredChanged: {
                                    miniMpris.expanded = hovered

                                    if (hovered)
                                        music.abrirMenu2()
                                    else
                                        music.solicitarCierre2()
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 10

                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight

                                text: player
                                    ? player.trackTitle + " - " + (player.trackAlbum || "Unknown Album")
                                    : "No player"
                            }
                        }
                           

                        Item {
                            Layout.fillWidth: true
                        }
            
                        Rectangle {
                            property bool on
                            id: botonMenuEnergia
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 40
                            color : "#bbbbbb"

                               MouseArea {
                                anchors.fill: parent
                                 onClicked: {
                                    if (!botonMenuEnergia.on) {
                                        var coords = botonMenuEnergia.mapToItem(null, 0, 0)

                                        power.abrirMenu(
                                            coords.x + (botonMenuEnergia.width / 2),
                                            coords.y + botonMenuEnergia.height
                                        )

                                        botonMenuEnergia.on = true
                                    } else {
                                        power.solicitarCierre()
                                        botonMenuEnergia.on = false
                                    }
                                }   
                            }
                        }
                        
                     }
                }
            }
        }
    }
}

