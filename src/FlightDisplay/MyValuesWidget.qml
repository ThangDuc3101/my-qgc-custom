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

    // Tạo một biến tắt để dễ dàng truy cập vào phương tiện đang hoạt động
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // Chỉ hiển thị widget này khi có phương tiện được kết nối
    visible: _activeVehicle !== null

    // Sử dụng GridLayout để sắp xếp các giá trị thành một bảng gọn gàng
    GridLayout
    {
        id: gridLayout
        anchors.centerIn: parent
        columns: 2 // 2 cột: Tên thông số và Giá trị
        columnSpacing: ScreenTools.defaultFontPixelWidth // Khoảng cách giữa các cột

        // Dòng 1: Tốc độ
        QGCLabel { text: qsTr("Tốc độ:") }
        QGCLabel {
            // Lấy giá trị tốc độ so với mặt đất, làm tròn đến 1 chữ số thập phân
            text: _activeVehicle ? _activeVehicle.groundSpeed.value.toFixed(1) + " m/s" : "--"
            font.bold: true
        }

        // Dòng 2: Độ cao
        QGCLabel { text: qsTr("Độ cao:") }
        QGCLabel {
            // Lấy giá trị độ cao tương đối so với điểm cất cánh
            text: _activeVehicle ? _activeVehicle.altitudeRelative.value.toFixed(1) + " m" : "--"
            font.bold: true
        }

        // Dòng 3: Cự ly
        QGCLabel { text: qsTr("Cự ly:") }
        QGCLabel {
            // Lấy khoảng cách đến điểm home, làm tròn đến số nguyên
            text: _activeVehicle ? _activeVehicle.distanceToHome.value.toFixed(0) + " m" : "--"
            font.bold: true
        }

        // Dòng 4: Trạng thái
        QGCLabel { text: qsTr("Trạng thái:") }
        QGCLabel {
            // Kết hợp trạng thái armed/disarmed và chế độ bay
            text: _activeVehicle ? (_activeVehicle.armed ? "ARMED" : "DISARMED") + " / " + _activeVehicle.flightMode : "--"
            font.bold: true
            color: _activeVehicle && _activeVehicle.armed ? "lightgreen" : "white" // Đổi màu khi ARMED
        }
        // Dòng 5: Thời gian bay
            QGCLabel { text: qsTr("Thời gian bay:") }
            QGCLabel {
                // Gọi hàm formatTime để chuyển đổi giây sang HH:MM:SS
                text: _activeVehicle ? formatTime(_activeVehicle.flightTime) : "00:00:00"
                font.bold: true
            }
        // Dòng 6: Pin
        QGCLabel { text: qsTr("Pin:") }
        QGCLabel {
            // Lấy phần trăm pin còn lại
            // text: _activeVehicle ? _activeVehicle.battery.percentRemaining.value.toFixed(0) + " %" : "--"
            text: {
                if (_activeVehicle) {
                    var pct = _activeVehicle.battery.percentRemaining.value;
                    // Chỉ hiển thị giá trị nếu nó là một con số hợp lệ (không phải NaN)
                    return isNaN(pct) ? "N/A" : pct.toFixed(0) + " %";
                }
                return "--";
            }
            font.bold: true
            color: _activeVehicle && _activeVehicle.battery.percentRemaining.value < 20 ? "orange" : "white" // Cảnh báo khi pin yếu
        }
    }

    function formatTime(totalSeconds) {
        if (isNaN(totalSeconds)) return "00:00:00";

        var hours   = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds - (hours * 3600)) / 60);
        var seconds = totalSeconds - (hours * 3600) - (minutes * 60);

        // Thêm số 0 vào trước nếu giá trị < 10
        if (hours   < 10) { hours   = "0" + hours; }
        if (minutes < 10) { minutes = "0" + minutes; }
        if (seconds < 10) { seconds = "0" + seconds; }

        return hours + ':' + minutes + ':' + seconds;
    }
}
