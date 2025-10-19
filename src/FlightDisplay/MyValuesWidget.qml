import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id: _root

    // implicitWidth và implicitHeight giờ sẽ tham chiếu đến gridLayout
    implicitWidth: gridLayout.implicitWidth + (_margins * 2)
    implicitHeight: gridLayout.implicitHeight + (_margins * 2)
    color:          Qt.rgba(0, 0, 0, 0.75)
    radius:         ScreenTools.defaultFontPixelWidth / 2

    property real _margins: ScreenTools.defaultFontPixelWidth
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var _missionController: globals.planMasterControllerFlyView.missionController

    // >>> THÊM MỚI: Thuộc tính và Connections để xử lý dữ liệu từ C++ <<<
    property string currentBoardStatus: "Đang kết nối..."

    Connections {
        target: _activeVehicle
        ignoreUnknownSignals: true

        function onUavInfoReceived(boardStatus, message) {
            _root.currentBoardStatus = boardStatus
            // message sẽ được dùng sau
        }
    }
    // >>> KẾT THÚC <<<

    // >>> BẮT ĐẦU SỬA LỖI: Sử dụng getFact cho tất cả các thuộc tính <<<
    // Tạo thuộc tính để giữ tham chiếu đến các Fact một cách nhất quán.
    property var flightTimeFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("FlightTime") : null
    property var pitchFact:      (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("Pitch") : null
    property var rollFact:       (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("Roll") : null

    // >>> THÊM MỚI: Tạo thuộc tính cho Fact AirSpeed <<<
    property var airSpeedFact:   (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("AirSpeed") : null

    // >>> KẾT THÚC SỬA LỖI <<<

    property real distanceToTarget: {
        if (_activeVehicle && _missionController && _missionController.visualItems.count > 1) {
            for (var i = _missionController.visualItems.count - 1; i >= 0; i--) {
                var item = _missionController.visualItems.get(i);
                if (item && item.specifiesCoordinate) {
                    return _activeVehicle.coordinate.distanceTo(item.coordinate);
                }
            }
        }
        return -1;
    }

    visible: _activeVehicle !== null

    // >>> THAY ĐỔI: Sử dụng GridLayout thay cho RowLayout <<<
    GridLayout {
        id: gridLayout
        anchors.centerIn: parent
        rows: 3
        columns: 3
        columnSpacing: _margins * 1.5
        rowSpacing: _margins / 2

        // --- HÀNG 1 ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Tốc độ"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: (_activeVehicle && _activeVehicle.groundSpeed) ? _activeVehicle.groundSpeed.valueString + " " + _activeVehicle.groundSpeed.units : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Gió"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: airSpeedFact ? (airSpeedFact.valueString + " " + airSpeedFact.units) : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Độ cao"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: (_activeVehicle && _activeVehicle.altitudeAMSL) ? _activeVehicle.altitudeAMSL.valueString + " " + _activeVehicle.altitudeRelative.units : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        // --- HÀNG 2 ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Q.đường"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: (_activeVehicle && _activeVehicle.flightDistance) ? _activeVehicle.flightDistance.valueString + " " + _activeVehicle.flightDistance.units : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Mục tiêu"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: distanceToTarget >= 0 ? distanceToTarget.toFixed(0) + " m" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("T.g bay"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: flightTimeFact ? flightTimeFact.valueString : "00:00:00"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        // --- HÀNG 3 ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Góc hướng"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: pitchFact ? (pitchFact.valueString + "độ") : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Góc liệng"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: rollFact ? (rollFact.valueString + "độ") : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Ngòi"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: {
                    if (_root.currentBoardStatus === "True") {
                        return "Đã mở";
                    } else if (_root.currentBoardStatus === "False") {
                        return "Chưa mở";
                    } else {
                        return _root.currentBoardStatus;
                    }
                }
                font.bold: true
                color: {
                    if (_root.currentBoardStatus === "True") {
                        return "red";
                    } else if (_root.currentBoardStatus === "False") {
                        return "lime";
                    } else {
                        return "white";
                    }
                }
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
