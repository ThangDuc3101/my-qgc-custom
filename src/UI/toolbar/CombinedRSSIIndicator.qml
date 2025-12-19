/****************************************************************************
 *
 * (c) 2009-2025 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

//-------------------------------------------------------------------------
//-- Combined RC + Telemetry RSSI Indicator
//-- Hiển thị cường độ tín hiệu điều khiển và dữ liệu
Item {
    id:             control
    width:          rssiContainer.width
    height:         ScreenTools.toolbarHeight * 1.4
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property bool _rcRSSIAvailable:     _activeVehicle ? (_activeVehicle.rcRSSI > 0 && _activeVehicle.rcRSSI <= 100) : false
    property bool _hasTelemetry:        _activeVehicle ? (_activeVehicle.telemetryLRSSI !== 0) : false
    property int  _rcRSSIValue:         _activeVehicle ? _activeVehicle.rcRSSI : 0
    property int  _telemetryLRSSI:      _activeVehicle ? _activeVehicle.telemetryLRSSI : 0
    
    // Monitor RSSI changes
    Connections {
        target: _activeVehicle
        ignoreUnknownSignals: true
        
        function onRcRSSIChanged(rssi) {
            console.log("RC RSSI Changed:", rssi)
        }
        
        function onTelemetryLRSSIChanged(rssi) {
            console.log("Telemetry RSSI Changed:", rssi)
        }
    }

    // Hàm lấy màu dựa trên chất lượng tín hiệu (cho RC RSSI - %)
    function getRCRSSIColor(rssi) {
        if (rssi <= 0 || rssi > 100) return "#888888"  // Xám - không có tín hiệu
        if (rssi >= 75) return "#00ff00"               // Xanh - rất tốt
        if (rssi >= 50) return "#ffff00"               // Vàng - tốt
        if (rssi >= 25) return "#ff9900"               // Cam - trung bình
        return "#ff0000"                               // Đỏ - yếu
    }

    // Hàm lấy màu dựa trên chất lượng tín hiệu (cho Telemetry RSSI - dBm)
    function getTelemetryRSSIColor(rssi) {
        if (rssi === 0) return "#888888"               // Xám - không có tín hiệu
        if (rssi >= -70) return "#00ff00"              // Xanh - rất tốt (-70 dBm trở lên)
        if (rssi >= -80) return "#ffff00"              // Vàng - tốt
        if (rssi >= -90) return "#ff9900"              // Cam - trung bình
        return "#ff0000"                               // Đỏ - yếu
    }

    Rectangle {
        id: rssiContainer
        anchors.fill: parent
        color: Qt.rgba(0.1, 0.1, 0.1, 0.3)
        border.color: "white"
        border.width: 2
        radius: 6
        visible: _activeVehicle

        Column {
            anchors.centerIn: parent
            spacing: 4

            QGCLabel {
                text: "RSSI"
                color: "white"
                font.family: "Monospace"
                font.pointSize: ScreenTools.smallFontPointSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            QGCLabel {
                text: {
                    if (_rcRSSIAvailable) return _rcRSSIValue.toString() + "%"
                    if (_hasTelemetry) return _telemetryLRSSI.toString() + "dBm"
                    return "N/A"
                }
                color: {
                    if (_rcRSSIAvailable) return getRCRSSIColor(_rcRSSIValue)
                    if (_hasTelemetry) return getTelemetryRSSIColor(_telemetryLRSSI)
                    return "#888888"
                }
                font.bold: true
                font.family: "Monospace"
                font.pointSize: ScreenTools.defaultFontPointSize * 1.2
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mainWindow.showIndicatorDrawer(rssiDetailPageComponent, control)
        }

        // Component chi tiết
        Component {
            id: rssiDetailPageComponent

            ToolIndicatorPage {
                showExpand: false

                contentComponent: SettingsGroupLayout {
                    heading: qsTr("Signal Strength (RSSI) Status")

                    // RC RSSI Section
                    LabelledLabel {
                        visible: _rcRSSIAvailable
                        label:      qsTr("RC RSSI")
                        labelText:  _activeVehicle ? (_activeVehicle.rcRSSI + "%") : "N/A"
                    }

                    LabelledLabel {
                        visible: _rcRSSIAvailable
                        label:      qsTr("RC Signal Quality")
                        labelText:  {
                            if (!_activeVehicle || !_rcRSSIAvailable) return "N/A"
                            var rssi = _activeVehicle.rcRSSI
                            if (rssi >= 75) return qsTr("Excellent")
                            if (rssi >= 50) return qsTr("Good")
                            if (rssi >= 25) return qsTr("Fair")
                            return qsTr("Poor")
                        }
                    }

                    Rectangle {
                        visible: _rcRSSIAvailable && _hasTelemetry
                        height: 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        color: "#666666"
                    }

                    // Telemetry RSSI Section
                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Telemetry Local RSSI")
                        labelText:  _activeVehicle ? (_activeVehicle.telemetryLRSSI + " dBm") : "N/A"
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Telemetry Remote RSSI")
                        labelText:  _activeVehicle ? (_activeVehicle.telemetryRRSSI + " dBm") : "N/A"
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Telemetry Signal Quality")
                        labelText:  {
                            if (!_activeVehicle || !_hasTelemetry) return "N/A"
                            var rssi = _activeVehicle.telemetryLRSSI
                            if (rssi >= -70) return qsTr("Excellent")
                            if (rssi >= -80) return qsTr("Good")
                            if (rssi >= -90) return qsTr("Fair")
                            return qsTr("Poor")
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("RX Errors")
                        labelText:  _activeVehicle ? _activeVehicle.telemetryRXErrors.toString() : "N/A"
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Errors Fixed")
                        labelText:  _activeVehicle ? _activeVehicle.telemetryFixed.toString() : "N/A"
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Local Noise")
                        labelText:  _activeVehicle ? (_activeVehicle.telemetryLNoise + " dBm") : "N/A"
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Remote Noise")
                        labelText:  _activeVehicle ? (_activeVehicle.telemetryRNoise + " dBm") : "N/A"
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("TX Buffer")
                        labelText:  _activeVehicle ? _activeVehicle.telemetryTXBuffer.toString() : "N/A"
                    }
                }
            }
        }
    }
}
