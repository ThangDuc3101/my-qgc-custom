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
    
    // Safer property access with explicit null checks
    property bool _rcRSSIAvailable: {
        if (!_activeVehicle || typeof _activeVehicle === 'undefined') return false
        try {
            return _activeVehicle.rcRSSI > 0 && _activeVehicle.rcRSSI <= 100
        } catch(e) {
            console.error("[RSSI] Error checking RC RSSI availability:", e)
            return false
        }
    }
    
    property bool _hasTelemetry: {
        if (!_activeVehicle || typeof _activeVehicle === 'undefined') return false
        try {
            return _activeVehicle.telemetryLRSSI !== 0
        } catch(e) {
            console.error("[RSSI] Error checking telemetry availability:", e)
            return false
        }
    }
    
    property int  _rcRSSIValue: {
        if (!_activeVehicle || typeof _activeVehicle === 'undefined') return 0
        try {
            return _activeVehicle.rcRSSI
        } catch(e) {
            console.error("[RSSI] Error reading rcRSSI:", e)
            return 0
        }
    }
    
    property int  _telemetryLRSSI: {
        if (!_activeVehicle || typeof _activeVehicle === 'undefined') return 0
        try {
            return _activeVehicle.telemetryLRSSI
        } catch(e) {
            console.error("[RSSI] Error reading telemetryLRSSI:", e)
            return 0
        }
    }
    
    // Monitor active vehicle changes (for debugging and state management)
    Connections {
        target: QGroundControl.multiVehicleManager
        
        function onActiveVehicleChanged(vehicle) {
            if (!vehicle) {
                console.warn("[RSSI] Vehicle disconnected - resetting RSSI values")
                control._rcRSSIValue = 0
                control._telemetryLRSSI = 0
            } else {
                console.log("[RSSI] New vehicle connected:", vehicle.id)
            }
        }
    }
    
    // Monitor RSSI changes (ENABLED only when vehicle is not null)
    Connections {
        target: _activeVehicle
        enabled: _activeVehicle !== null  // ← CRITICAL: Disable connection when null
        ignoreUnknownSignals: true
        
        function onRcRSSIChanged(rssi) {
            try {
                if (!_activeVehicle) {
                    console.warn("[RSSI] _activeVehicle is null in RC RSSI handler - ignoring signal")
                    return
                }
                console.log("[RSSI] RC RSSI changed:", rssi)
            } catch(e) {
                console.error("[RSSI] Exception in RC RSSI handler:", e.toString())
            }
        }
        
        function onTelemetryLRSSIChanged(rssi) {
            try {
                if (!_activeVehicle) {
                    console.warn("[RSSI] _activeVehicle is null in Telemetry RSSI handler - ignoring signal")
                    return
                }
                console.log("[RSSI] Telemetry RSSI changed:", rssi)
            } catch(e) {
                console.error("[RSSI] Exception in Telemetry RSSI handler:", e.toString())
            }
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
                        labelText:  {
                            try {
                                return _activeVehicle ? (_activeVehicle.rcRSSI + "%") : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading RC RSSI in detail page:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _rcRSSIAvailable
                        label:      qsTr("RC Signal Quality")
                        labelText:  {
                            try {
                                if (!_activeVehicle || !_rcRSSIAvailable) return "N/A"
                                var rssi = _activeVehicle.rcRSSI
                                if (rssi >= 75) return qsTr("Excellent")
                                if (rssi >= 50) return qsTr("Good")
                                if (rssi >= 25) return qsTr("Fair")
                                return qsTr("Poor")
                            } catch(e) {
                                console.error("[RSSI] Error determining RC signal quality:", e)
                                return "N/A"
                            }
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
                        labelText:  {
                            try {
                                return _activeVehicle ? (_activeVehicle.telemetryLRSSI + " dBm") : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading telemetry local RSSI:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Telemetry Remote RSSI")
                        labelText:  {
                            try {
                                return _activeVehicle ? (_activeVehicle.telemetryRRSSI + " dBm") : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading telemetry remote RSSI:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Telemetry Signal Quality")
                        labelText:  {
                            try {
                                if (!_activeVehicle || !_hasTelemetry) return "N/A"
                                var rssi = _activeVehicle.telemetryLRSSI
                                if (rssi >= -70) return qsTr("Excellent")
                                if (rssi >= -80) return qsTr("Good")
                                if (rssi >= -90) return qsTr("Fair")
                                return qsTr("Poor")
                            } catch(e) {
                                console.error("[RSSI] Error determining telemetry signal quality:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("RX Errors")
                        labelText:  {
                            try {
                                return _activeVehicle ? _activeVehicle.telemetryRXErrors.toString() : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading RX errors:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Errors Fixed")
                        labelText:  {
                            try {
                                return _activeVehicle ? _activeVehicle.telemetryFixed.toString() : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading errors fixed:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Local Noise")
                        labelText:  {
                            try {
                                return _activeVehicle ? (_activeVehicle.telemetryLNoise + " dBm") : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading local noise:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("Remote Noise")
                        labelText:  {
                            try {
                                return _activeVehicle ? (_activeVehicle.telemetryRNoise + " dBm") : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading remote noise:", e)
                                return "N/A"
                            }
                        }
                    }

                    LabelledLabel {
                        visible: _hasTelemetry
                        label:      qsTr("TX Buffer")
                        labelText:  {
                            try {
                                return _activeVehicle ? _activeVehicle.telemetryTXBuffer.toString() : "N/A"
                            } catch(e) {
                                console.error("[RSSI] Error reading TX buffer:", e)
                                return "N/A"
                            }
                        }
                    }
                }
            }
        }
    }
}
