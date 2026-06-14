import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: toplevel
    implicitHeight: 200
    implicitWidth: 1000
    property var images: []
    color: "transparent"
    Process {
        id: findImages

        command: [
            "sh",
            "-c",
            "find /home/rodolfo/Pictures/Wallpapers -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\)"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                toplevel.images =
                    text.trim() === ""
                    ? []
                    : text.trim().split("\n")

                console.log(toplevel.images)
            }
        }
    }

    Component.onCompleted: {
        findImages.running = true
    }
    Item{
        anchors.fill:parent
        Rectangle{
            color: "red"
            anchors.fill: parent
            radius: 8
        }
    
          Flow {                                                                                                                                                                                                          
            anchors.fill: parent                                                                                                                                                                                        
            spacing: 23              
            anchors.margins: 20                                                                                                                                                                  
            Repeater {                                                                                                                                                                                                  
                model: toplevel.images
                delegate: Rectangle {
                    width: 200
                    height: 150
                    radius: 2

                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2   // para que el borde sea visible
            
                        source: "file://" + modelData
                         sourceSize.width: 2000
                        sourceSize.height: 2000
                    
                    }   
                }                                                                                                                                                                    
            } 
        }
    }
}

