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

    // Lấy các thành phần N và E của tốc độ gió
    property var windSpeedNFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("windSpeedN") : null
    property var windSpeedEFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("windSpeedE") : null

    // Thuộc tính để tính toán và định dạng chuỗi tốc độ gió
    property string calculatedWindSpeedString: {
        if (windSpeedNFact && windSpeedEFact) {
            var n = windSpeedNFact.rawValue;
            var e = windSpeedEFact.rawValue;
            var speed = Math.sqrt(n*n + e*e);
            var units = windSpeedNFact.units;
            return speed.toFixed(1) + " " + units;
        }
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
            QGCLabel { text: qsTr("Air speed"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: airSpeedFact ? (airSpeedFact.valueString + " " + airSpeedFact.units) : "--"
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

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Wind Speed"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: calculatedWindSpeedString
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("T.gian bay"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel {
                text: flightTimeFact ? flightTimeFact.valueString : "00:00:00"
                font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter
            }
        }

        // >>> SỬA ĐỔI: Cột hiển thị trạng thái Ngòi <<<
        ColumnLayout {
            spacing: _margins / 4

            // 1. Đổi tiêu đề thành "Ngòi"
            QGCLabel { text: qsTr("Ngòi"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }

            QGCLabel {
                // 2. Dùng biểu thức điều kiện để hiển thị văn bản
                text: {
                    if (_root.currentBoardStatus === "True") {
                        return "Đã mở";
                    } else if (_root.currentBoardStatus === "False") {
                        return "Chưa mở";
                    } else {
                        return _root.currentBoardStatus; // Hiển thị lỗi như "N/A", "Lỗi JSON", ...
                    }
                }

                font.bold: true

                // 3. Dùng biểu thức điều kiện để thay đổi màu sắc
                color: {
                    if (_root.currentBoardStatus === "True") {
                        return "red"; // Màu đỏ
                    } else if (_root.currentBoardStatus === "False") {
                        return "lime"; // Màu xanh lá (lime sáng hơn green)
                    } else {
                        return "white"; // Màu trắng cho các trạng thái khác
                    }
                }

                Layout.alignment: Qt.AlignHCenter
            }
        }
        // >>> KẾT THÚC SỬA ĐỔI <<<
        // >>> KẾT THÚC <<<
    }
}
