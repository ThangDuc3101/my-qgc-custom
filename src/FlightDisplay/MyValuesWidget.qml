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

    // >>> BẮT ĐẦU SỬA LỖI: Sử dụng getFact cho tất cả các thuộc tính <<<
    // Tạo thuộc tính để giữ tham chiếu đến các Fact một cách nhất quán.
    property var flightTimeFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("FlightTime") : null
    property var pitchFact:      (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("Pitch") : null
    property var rollFact:       (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("Roll") : null

    // Lấy các thành phần N và E của tốc độ gió
    property var windSpeedNFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("windSpeedN") : null
    property var windSpeedEFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("windSpeedE") : null

    // Thuộc tính để tính toán và định dạng chuỗi tốc độ gió
    property string calculatedWindSpeedString: {
        // Chỉ tính toán nếu cả hai Fact đều tồn tại
        if (windSpeedNFact && windSpeedEFact) {
            var n = windSpeedNFact.rawValue;
            var e = windSpeedEFact.rawValue;

            // Tính toán độ lớn (tốc độ)
            var speed = Math.sqrt(n*n + e*e);

            // Lấy đơn vị từ một trong các Fact thành phần
            var units = windSpeedNFact.units;

            // Định dạng chuỗi kết quả với 1 chữ số thập phân
            return speed.toFixed(1) + " " + units;
        }
        // Trả về "--" nếu không có dữ liệu
        return "--,-- m/s";
    }
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

    RowLayout {
        id: mainRowLayout
        anchors.centerIn: parent
        spacing: _margins * 1.5

        // --- CÁC CỘT DỮ LIỆU ---
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
                text: pitchFact ? (pitchFact.valueString + pitchFact.units) : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Roll"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: rollFact ? (rollFact.valueString + rollFact.units) : "--"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        // >>> BẮT ĐẦU SỬA LỖI: Cập nhật cột Tốc độ gió <<<
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Tốc độ gió"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                // Liên kết với thuộc tính đã được tính toán
                text: calculatedWindSpeedString
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
        // >>> KẾT THÚC SỬA LỖI <<<

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("T.gian bay"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: flightTimeFact ? flightTimeFact.valueString : "00:00:00"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
