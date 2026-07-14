/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

QGCFlickable {
    id:             root
    contentHeight:  geoFenceEditorRect.height
    clip:           true

    property var    myGeoFenceController
    property var    flightMap

    readonly property real  _editFieldWidth:    Math.min(width - _margin * 2, ScreenTools.defaultFontPixelWidth * 15)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _radius:            ScreenTools.defaultFontPixelWidth / 2

    Rectangle {
        id:     geoFenceEditorRect
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: geoFenceItems.y + geoFenceItems.height + (_margin * 2)
        radius: _radius
        color:  qgcPal.missionItemEditor

        QGCLabel {
            id:                 geoFenceLabel
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.top:        parent.top
            text:               qsTr("GeoFence")
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
        }

        Rectangle {
            id:                 geoFenceItems
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        geoFenceLabel.bottom
            height:             fenceColumn.y + fenceColumn.height + (_margin * 2)
            color:              qgcPal.windowShadeDark
            radius:             _radius

            Column {
                id:                 fenceColumn
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margin

                QGCLabel {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    wrapMode:           Text.WordWrap
                    font.pointSize:     myGeoFenceController.supported ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                    text:               myGeoFenceController.supported ?
                                            qsTr("GeoFencing allows you to set a virtual fence around the area you want to fly in.") :
                                            qsTr("This vehicle does not support GeoFence.")
                }

                Column {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    spacing:            _margin
                    visible:            myGeoFenceController.supported

                    Repeater {
                        model: myGeoFenceController.params

                        Item {
                            width:  fenceColumn.width
                            height: textField.height

                            property bool showCombo: modelData.enumStrings.length > 0

                            QGCLabel {
                                id:                 textFieldLabel
                                anchors.baseline:   textField.baseline
                                text:               myGeoFenceController.paramLabels[index]
                            }

                            FactTextField {
                                id:             textField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                showUnits:      true
                                fact:           modelData
                                visible:        !parent.showCombo
                            }

                            FactComboBox {
                                id:             comboField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                indexModel:     false
                                fact:           showCombo ? modelData : _nullFact
                                visible:        parent.showCombo

                                property var _nullFact: Fact { }
                            }
                        }
                    }

                    SectionHeader {
                        id:             insertSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Insert GeoFence")
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Polygon Fence")

                        onClicked: {
                            var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                            var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                            var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                            myGeoFenceController.addInclusionPolygon(topLeftCoord, bottomRightCoord)
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Circular Fence")

                        onClicked: {
                            var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                            var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                            var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                            myGeoFenceController.addInclusionCircle(topLeftCoord, bottomRightCoord)
                        }
                    }

                    SectionHeader {
                        id:             polygonSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Polygon Fences")
                    }

                    QGCLabel {
                        text:       qsTr("None")
                        visible:    polygonSection.checked && myGeoFenceController.polygons.count === 0
                    }

                    GridLayout {
                        Layout.fillWidth:   true
                        columns:            4
                        flow:               GridLayout.TopToBottom
                        visible:            polygonSection.checked && myGeoFenceController.polygons.count > 0

                        QGCLabel { text: qsTr("Inclusion"); Layout.column: 0; Layout.alignment: Qt.AlignHCenter }
                        Repeater {
                            model: myGeoFenceController.polygons
                            QGCCheckBox {
                                checked:            object.inclusion
                                onClicked:          object.inclusion = checked
                                Layout.alignment:   Qt.AlignHCenter
                            }
                        }

                        QGCLabel { text: qsTr("Edit"); Layout.column: 1; Layout.alignment: Qt.AlignHCenter }
                        Repeater {
                            model: myGeoFenceController.polygons
                            QGCRadioButton {
                                checked:            object.interactive
                                Layout.alignment:   Qt.AlignHCenter
                                onCheckedChanged: {
                                    if(checked) {
                                        myGeoFenceController.clearAllInteractive()
                                        object.interactive = true
                                    }
                                }
                            }
                        }

                        QGCLabel { text: qsTr("H.Chỉnh"); Layout.column: 2; Layout.alignment: Qt.AlignHCenter }
                        Repeater {
                            model: myGeoFenceController.polygons
                            QGCButton {
                                text: qsTr("300m")
                                Layout.alignment: Qt.AlignHCenter
                                enabled: model.object.path.length >= 3
                                onClicked: {
                                    var sourcePolygon = model.object;
                                    var oldPath = sourcePolygon.path;
                                    var totalLat = 0.0, totalLon = 0.0;
                                    for (var i = 0; i < oldPath.length; i++) {
                                        totalLat += oldPath[i].latitude;
                                        totalLon += oldPath[i].longitude;
                                    }
                                    var centroid = QtPositioning.coordinate(totalLat / oldPath.length, totalLon / oldPath.length);
                                    var newCoords = [];
                                    var shrinkDistanceMeters = 300.0;
                                    for (var j = 0; j < oldPath.length; j++) {
                                        var vertex = oldPath[j];
                                        var distanceToCentroid = centroid.distanceTo(vertex);
                                        var azimuth = centroid.azimuthTo(vertex);
                                        var newDistance = distanceToCentroid - shrinkDistanceMeters;
                                        if (newDistance > 0) {
                                            newCoords.push(centroid.atDistanceAndAzimuth(newDistance, azimuth));
                                        } else {
                                            newCoords.push(vertex);
                                        }
                                    }
                                    myGeoFenceController.addInclusionPolygonFromVertices(newCoords);
                                }
                            }
                        }

                        QGCLabel { text: qsTr("Delete"); Layout.column: 3; Layout.alignment: Qt.AlignHCenter }
                        Repeater {
                            model: myGeoFenceController.polygons
                            QGCButton {
                                text:               qsTr("Del")
                                Layout.alignment:   Qt.AlignHCenter
                                onClicked:          myGeoFenceController.deletePolygon(index)
                            }
                        }
                    }

                    SectionHeader {
                        id:             circleSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Circular Fences")
                    }

                    QGCLabel {
                        text:       qsTr("None")
                        visible:    circleSection.checked && myGeoFenceController.circles.count === 0
                    }

                    GridLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        columns:            4
                        flow:               GridLayout.TopToBottom
                        visible:            circleSection.checked && myGeoFenceController.circles.count > 0

                        QGCLabel { text: qsTr("Inclusion"); Layout.column: 0; Layout.alignment: Qt.AlignHCenter }
                        Repeater { model: myGeoFenceController.circles; QGCCheckBox { checked: object.inclusion; onClicked: object.inclusion = checked; Layout.alignment: Qt.AlignHCenter } }
                        QGCLabel { text: qsTr("Edit"); Layout.column: 1; Layout.alignment: Qt.AlignHCenter }
                        Repeater { model: myGeoFenceController.circles; QGCRadioButton { checked: object.interactive; Layout.alignment: Qt.AlignHCenter; onCheckedChanged: if(checked){ myGeoFenceController.clearAllInteractive(); object.interactive = true; } } }
                        QGCLabel { text: qsTr("Radius"); Layout.column: 2; Layout.alignment: Qt.AlignHCenter }
                        Repeater { model: myGeoFenceController.circles; FactTextField { fact: object.radius; Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter } }
                        QGCLabel { text: qsTr("Delete"); Layout.column: 3; Layout.alignment: Qt.AlignHCenter }
                        Repeater { model: myGeoFenceController.circles; QGCButton { text: qsTr("Del"); Layout.alignment: Qt.AlignHCenter; onClicked: myGeoFenceController.deleteCircle(index) } }
                    }

                    SectionHeader {
                        id:             breachReturnSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Breach Return Point")
                    }

                    QGCButton {
                        text:               qsTr("Add Breach Return Point")
                        visible:            breachReturnSection.visible && !myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        onClicked: myGeoFenceController.breachReturnPoint = flightMap.center
                    }

                    QGCButton {
                        text:               qsTr("Remove Breach Return Point")
                        visible:            breachReturnSection.visible && myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        onClicked: myGeoFenceController.breachReturnPoint = QtPositioning.coordinate()
                    }

                    ColumnLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing:            _margin
                        visible:            breachReturnSection.visible && myGeoFenceController.breachReturnPoint.isValid

                        QGCLabel { text: qsTr("Altitude") }
                        FactTextField { fact: myGeoFenceController.breachReturnAltitude }
                    }

                    SectionHeader {
                        id:             swarmFenceSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Swarm")
                    }

                    QGCButton {
                        text:               qsTr("Upload Fence to All Vehicles")
                        visible:            swarmFenceSection.visible
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        enabled:            QGroundControl.multiVehicleManager.vehicles.count > 0
                        onClicked:          myGeoFenceController.sendToAllVehicles()
                    }
                }
            }
        }
    }
}
