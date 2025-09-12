import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id: _root

    implicitWidth: mainRowLayout.implicitWidth + (_margins * 2)
    implicitHeight: mainRowLayout.implicitHeight + (_margins * 2)
    color:          Qt.rgba(0, 0, 0, 0.75)
    radius:         ScreenTools.defaultFontPixelWidth / 2

    property real _margins: ScreenTools.defaultFontPixelWidth
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var _missionController: globals.planMasterControllerFlyView.missionController

    // Tạo một thuộc tính để giữ tham chiếu đến Fact thời gian bay cho sạch sẽ
    // Nó sẽ tự động được cập nhật khi _activeVehicle thay đổi
    property var flightTimeFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("FlightTime") : null

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

    RowLayout {
        id: mainRowLayout
        anchors.centerIn: parent
        spacing: _margins * 1.5

        // --- CÁC CỘT DỮ LIỆU (SỬ DỤNG PHƯƠNG PHÁP TRUY CẬP ĐÚNG) ---
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
            QGCLabel { text: qsTr("Độ cao"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: (_activeVehicle && _activeVehicle.altitudeRelative) ? _activeVehicle.altitudeRelative.valueString + " " + _activeVehicle.altitudeRelative.units : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
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
            QGCLabel { text: qsTr("Pitch"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: (_activeVehicle && _activeVehicle.pitch) ? _activeVehicle.pitch.valueString + _activeVehicle.pitch.units : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Roll"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: (_activeVehicle && _activeVehicle.roll) ? _activeVehicle.roll.valueString + _activeVehicle.roll.units : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("T.gian bay"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                // Liên kết trực tiếp với 'valueString' của Fact đã được tìm thấy
                text: flightTimeFact ? flightTimeFact.valueString : "00:00:00"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
