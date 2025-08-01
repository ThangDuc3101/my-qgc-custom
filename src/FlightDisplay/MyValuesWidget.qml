import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id: _root

    // Chiều rộng và chiều cao sẽ tự động điều chỉnh theo nội dung bên trong
    implicitWidth: gridLayout.width + (_margins * 2)
    implicitHeight: gridLayout.height + (_margins * 2)

    color:          Qt.rgba(0, 0, 0, 0.75) // Nền đen mờ
    radius:         ScreenTools.defaultFontPixelWidth / 2 // Bo góc

    property real _margins: ScreenTools.defaultFontPixelWidth

    // --- CÁC BIẾN TRUY CẬP DỮ LIỆU ---
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    // Lấy MissionController trực tiếp từ đối tượng globals để đảm bảo tính ổn định
    property var _missionController: globals.planMasterControllerFlyView.missionController

    // --- THUỘC TÍNH TÍNH TOÁN (PHIÊN BẢN ROBUST CUỐI CÙNG) ---
        property real distanceToTarget: {
            // Chỉ tính toán khi có đủ các đối tượng cần thiết
            if (_activeVehicle && _missionController && _missionController.visualItems.count > 1) {

                // Lặp ngược từ cuối danh sách để tìm waypoint cuối cùng có tọa độ
                for (var i = _missionController.visualItems.count - 1; i >= 0; i--) {
                    var item = _missionController.visualItems.get(i);

                    // Tìm item cuối cùng thực sự có tọa độ
                    if (item && item.specifiesCoordinate) {
                        // Ngay khi tìm thấy, tính khoảng cách và thoát khỏi hàm
                        var dist = _activeVehicle.coordinate.distanceTo(item.coordinate);
                        // console.log("Distance to last valid item (Seq:", item.sequenceNumber, ") is", dist); // Bỏ comment để debug
                        return dist;
                    }
                }
            }

            // Nếu không tìm thấy waypoint nào có tọa độ (ví dụ: kế hoạch trống), trả về -1
            return -1;
        }
        // ----------------------------------------------------

    // Chỉ hiển thị widget này khi có phương tiện được kết nối
    visible: _activeVehicle !== null

    // Sử dụng GridLayout để sắp xếp các giá trị thành một bảng gọn gàng
    GridLayout
    {
        id: gridLayout
        anchors.centerIn: parent
        columns: 2
        columnSpacing: ScreenTools.defaultFontPixelWidth

        // Dòng 1: Tốc độ
        QGCLabel { text: qsTr("Tốc độ:") }
        QGCLabel {
            text: _activeVehicle ? _activeVehicle.groundSpeed.value.toFixed(1) + " m/s" : "--"
            font.bold: true
        }

        // Dòng 2: Độ cao
        QGCLabel { text: qsTr("Độ cao:") }
        QGCLabel {
            text: _activeVehicle ? _activeVehicle.altitudeRelative.value.toFixed(1) + " m" : "--"
            font.bold: true
        }

        // Dòng 3: Cự ly (về Launch)
        QGCLabel { text: qsTr("Cự ly (về Launch):") }
        QGCLabel {
            text: _activeVehicle ? _activeVehicle.distanceToHome.value.toFixed(0) + " m" : "--"
            font.bold: true
        }

        // Dòng 4: Quãng đường đã đi
        QGCLabel { text: qsTr("Quãng đường:") }
        QGCLabel {
            text: _activeVehicle ? _activeVehicle.flightDistance.value.toFixed(0) + " m" : "--"
            font.bold: true
        }

        // Dòng 5: Khoảng cách đến mục tiêu
        QGCLabel { text: qsTr("Đến mục tiêu:") }
        QGCLabel {
            text: distanceToTarget >= 0 ? distanceToTarget.toFixed(0) + " m" : "--"
            font.bold: true
        }

        // Dòng 6: Trạng thái
        QGCLabel { text: qsTr("Trạng thái:") }
        QGCLabel {
            text: _activeVehicle ? (_activeVehicle.armed ? "ARMED" : "DISARMED") + " / " + _activeVehicle.flightMode : "--"
            font.bold: true
            color: _activeVehicle && _activeVehicle.armed ? "lightgreen" : "white"
        }

        // Dòng 7: Thời gian bay
        QGCLabel { text: qsTr("Thời gian bay:") }
        QGCLabel {
            text: _activeVehicle ? formatTime(_activeVehicle.flightTime) : "00:00:00"
            font.bold: true
        }

        // Dòng 8: Pin
        QGCLabel { text: qsTr("Pin:") }
        QGCLabel {
            text: {
                if (_activeVehicle) {
                    var pct = _activeVehicle.battery.percentRemaining.value;
                    return isNaN(pct) ? "N/A" : pct.toFixed(0) + " %";
                }
                return "--";
            }
            font.bold: true
            color: _activeVehicle && _activeVehicle.battery.percentRemaining.value < 20 ? "orange" : "white"
        }
    }

    function formatTime(totalSeconds) {
        if (isNaN(totalSeconds)) return "00:00:00";
        var hours   = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds - (hours * 3600)) / 60);
        var seconds = totalSeconds - (hours * 3600) - (minutes * 60);
        if (hours   < 10) { hours   = "0" + hours; }
        if (minutes < 10) { minutes = "0" + minutes; }
        if (seconds < 10) { seconds = "0" + seconds; }
        return hours + ':' + minutes + ':' + seconds;
    }
}
