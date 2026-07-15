/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls


import QGroundControl.FlightMap
import QGroundControl.FlightDisplay

Item {
    property real   _margin:              ScreenTools.defaultFontPixelWidth / 2
    property real   _widgetHeight:        ScreenTools.defaultFontPixelHeight * 2.5
    property var    _guidedController:    globals.guidedControllerFlyView
    property var    _activeVehicleColor:  "green"
    property var    _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property var    selectedVehicles:     QGroundControl.multiVehicleManager.selectedVehicles

    implicitHeight: vehicleList.contentHeight

    function armAvailable() {
        for (var i = 0; i < selectedVehicles.count; i++) {
            var vehicle = selectedVehicles.get(i)
            if (vehicle.armed === false) {
                return true
            }
        }
        return false
    }


    function disarmAvailable() {
        for (var i = 0; i < selectedVehicles.count; i++) {
            var vehicle = selectedVehicles.get(i)
            if (vehicle.armed === true) {
                return true
            }
        }
        return false
    }

    function startAvailable() {
        for (var i = 0; i < selectedVehicles.count; i++) {
            var vehicle = selectedVehicles.get(i)
            if (vehicle.armed === true && vehicle.flightMode !== vehicle.missionFlightMode){
                return true
            }
        }
        return false
    }

    function pauseAvailable() {
        for (var i = 0; i < selectedVehicles.count; i++) {
            var vehicle = selectedVehicles.get(i)
            if (vehicle.armed === true && vehicle.pauseVehicleSupported) {
                return true
            }
        }
        return false
    }

    function selectVehicle(vehicleId) {
        QGroundControl.multiVehicleManager.selectVehicle(vehicleId)
    }

    function deselectVehicle(vehicleId) {
        QGroundControl.multiVehicleManager.deselectVehicle(vehicleId)
    }

    function toggleSelect(vehicleId) {
        if (!vehicleSelected(vehicleId)) {
            selectVehicle(vehicleId)
        } else {
            deselectVehicle(vehicleId)
        }
    }

    function selectAll() {
        var vehicles = QGroundControl.multiVehicleManager.vehicles
        for (var i = 0; i < vehicles.count; i++) {
            var vehicle = vehicles.get(i)
            var vehicleId = vehicle.id
            if (!vehicleSelected(vehicleId)) {
                selectVehicle(vehicleId)
            }
        }
    }

    function deselectAll() {
        QGroundControl.multiVehicleManager.deselectAllVehicles()
    }

    function vehicleSelected(vehicleId) {
        for (var i = 0; i < selectedVehicles.count; i++ ) {
            var currentId = selectedVehicles.get(i).id
            if (vehicleId === currentId) {
                return true
            }
        }
        return false
    }

    QGCListView {
        id:                 vehicleList
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        spacing:            ScreenTools.defaultFontPixelHeight / 2
        orientation:        ListView.Vertical
        model:              QGroundControl.multiVehicleManager.vehicles
        cacheBuffer:        _cacheBuffer < 0 ? 0 : _cacheBuffer
        clip:               true

        property real _cacheBuffer:     height * 2

        delegate: Rectangle {
            width:          vehicleList.width
            height:         innerColumn.height + _margin * 2
            color:          QGroundControl.multiVehicleManager.activeVehicle == _vehicle ? _activeVehicleColor : qgcPal.button
            radius:         _margin
            border.width:   _linkLost ? 3 : (_vehicle && vehicleSelected(_vehicle.id) ? 2 : 0)
            border.color:   _linkLost ? qgcPal.colorRed : qgcPal.text

            property var    _vehicle:   object
            property bool   _linkLost:  !!(_vehicle && _vehicle.vehicleLinkManager && _vehicle.vehicleLinkManager.communicationLost)

            PlanMasterController {
                id: cardPlanController
                Component.onCompleted: startStaticActiveVehicle(_vehicle)
            }
            property var  _cardMissionController: cardPlanController.missionController
            property real _cardDistanceToTarget: -1

            function _updateCardDistanceToTarget() {
                if (_vehicle && _cardMissionController && _cardMissionController.visualItems.count > 1) {
                    for (var i = _cardMissionController.visualItems.count - 1; i >= 0; i--) {
                        var item = _cardMissionController.visualItems.get(i)
                        if (item && item.specifiesCoordinate) {
                            _cardDistanceToTarget = _vehicle.coordinate.distanceTo(item.coordinate)
                            return
                        }
                    }
                }
                _cardDistanceToTarget = -1
            }

            Timer {
                id:             _distanceTimer
                interval:       1500
                repeat:         true
                running:        true
                onTriggered:    _updateCardDistanceToTarget()
            }

            Component.onCompleted: _updateCardDistanceToTarget()

            QGCMouseArea {
                anchors.fill:       parent
                onClicked:          toggleSelect(_vehicle.id)
            }

            ColumnLayout {
                anchors.top:        parent.top
                anchors.right:      parent.right
                anchors.margins:    _margin
                spacing:            _margin / 2

                QGCLabel {
                    text:  "🔋 " + ((_vehicle && _vehicle.batteries.count > 0) ? (_vehicle.batteries.get(0).percentRemaining.valueString + "%") : "--")
                    color: qgcPal.text
                    font.pointSize:   ScreenTools.mediumFontPointSize
                    Layout.alignment: Qt.AlignRight
                }

                QGCLabel {
                    text:  "🛰 " + ((_vehicle && _vehicle.gps) ? _vehicle.gps.count.valueString : "--")
                    color: qgcPal.text
                    font.pointSize:   ScreenTools.mediumFontPointSize
                    Layout.alignment: Qt.AlignRight
                }
            }

            Column {
                id:                         innerColumn
                anchors.centerIn:           parent
                spacing:                    _margin

                RowLayout {
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.margins:    _margin
                    spacing:            _margin
                    visible:            !_linkLost

                    IntegratedCompassAttitude {
                        id: compassWidget
                        compassRadius:              _widgetHeight / 2 - attitudeSize / 2
                        compassBorder:              0
                        attitudeSize:               ScreenTools.defaultFontPixelWidth / 2
                        attitudeSpacing:            attitudeSize / 2
                        usedByMultipleVehicleList:   true
                        vehicle:                     _vehicle
                    }

                    QGCLabel {
                        text: " | "
                        font.pointSize:       ScreenTools.largeFontPointSize
                        color:                qgcPal.text
                        Layout.alignment:     Qt.AlignHCenter
                    }

                    QGCLabel {
                        text:                 _vehicle ? _vehicle.id : ""
                        font.pointSize:       ScreenTools.largeFontPointSize
                        color:                qgcPal.text
                        Layout.alignment:     Qt.AlignHCenter
                    }

                    QGCLabel {
                        text: " | "
                        font.pointSize:       ScreenTools.largeFontPointSize
                        color:                qgcPal.text
                        Layout.alignment:     Qt.AlignHCenter
                    }

                    ColumnLayout {
                        spacing:              _margin
                        Layout.rightMargin:   compassWidget.width / 4
                        Layout.alignment:     Qt.AlignCenter

                        FlightModeMenu {
                            Layout.alignment:     Qt.AlignHCenter
                            font.pointSize:       ScreenTools.largeFontPointSize
                            color:                qgcPal.text
                            currentVehicle:       _vehicle
                        }

                        QGCLabel {
                            Layout.alignment:     Qt.AlignHCenter
                            text:                 _vehicle && _vehicle.armed ? qsTr("Armed") : qsTr("Disarmed")
                            color:                qgcPal.text
                        }
                    }

                }

                QGCLabel {
                    anchors.horizontalCenter:  parent.horizontalCenter
                    visible:                   _linkLost
                    text:                      qsTr("MẤT LIÊN LẠC")
                    color:                     qgcPal.colorRed
                    font.bold:                 true
                }

                QGCButton {
                    anchors.horizontalCenter:  parent.horizontalCenter
                    text:                      QGroundControl.multiVehicleManager.activeVehicle === _vehicle ? qsTr("Active") : qsTr("Set Active")
                    enabled:                   _vehicle && QGroundControl.multiVehicleManager.activeVehicle !== _vehicle

                    onClicked: {
                        QGroundControl.multiVehicleManager.activeVehicle = _vehicle
                    }
                }

                QGCFlickable {
                    anchors.horizontalCenter:   parent.horizontalCenter
                    width:          Math.min(contentWidth, vehicleList.width)
                    height:         control.height
                    contentWidth:   control.width
                    contentHeight:  control.height

                    TelemetryValuesBar {
                        id:                     control
                        settingsGroup:          factValueGrid.vehicleCardSettingsGroup
                        specificVehicleForCard: _vehicle
                    }
                }

                Rectangle {
                    anchors.horizontalCenter:   parent.horizontalCenter
                    width:          extraRowLayout.width + _margin * 2
                    height:         extraRowLayout.height + _margin * 2
                    color:          qgcPal.window
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    opacity:        0.75

                    RowLayout {
                        id:                 extraRowLayout
                        anchors.centerIn:   parent
                        spacing:            _margin

                        QGCLabel {
                            text:  "⌖ " + (_cardDistanceToTarget >= 0 ? (_cardDistanceToTarget.toFixed(0) + " m") : "--")
                            color: qgcPal.text
                        }

                        QGCLabel {
                            text:  "⏱ " + (_vehicle && _vehicle.getFact("FlightTime") ? _vehicle.getFact("FlightTime").valueString : "00:00:00")
                            color: qgcPal.text
                        }
                    }
                }
            }
        }
    }
}
