import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id: _root

    // Chiều rộng và chiều cao sẽ tự động điều chỉnh theo nội dung bên trong
    implicitWidth: mainRowLayout.implicitWidth + (_margins * 2)
    implicitHeight: mainRowLayout.implicitHeight + (_margins * 2)

    color:          Qt.rgba(0, 0, 0, 0.75) // Nền đen mờ
    radius:         ScreenTools.defaultFontPixelWidth / 2 // Bo góc

    property real _margins: ScreenTools.defaultFontPixelWidth

    // --- CÁC BIẾN TRUY CẬP DỮ LIỆU ---
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var _missionController: globals.planMasterControllerFlyView.missionController

    // --- THUỘC TÍNH TÍNH TOÁN ---
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

    // Chỉ hiển thị widget này khi có phương tiện được kết nối
    visible: _activeVehicle !== null

    // SỬ DỤNG ROWLAYOUT LÀM BỐ CỤC CHÍNH
    RowLayout {
        id: mainRowLayout
        anchors.centerIn: parent
        spacing: _margins * 1.5 // Tăng khoảng cách giữa các cột

        // --- CỘT 1: Tốc độ ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Tốc độ"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: _activeVehicle ? _activeVehicle.groundSpeed.value.toFixed(1) + " m/s" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }

        // --- CỘT 2: Độ cao ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Độ cao"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: _activeVehicle ? _activeVehicle.altitudeRelative.value.toFixed(1) + " m" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }

        // >>> BẮT ĐẦU THAY ĐỔI <<<
        // --- CỘT 3: Quãng đường (Thay cho Cự ly) ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Q.đường"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter } // Nhãn đã đổi
            QGCLabel { text: _activeVehicle ? _activeVehicle.flightDistance.value.toFixed(0) + " m" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter } // Nguồn dữ liệu đã đổi
        }
        // >>> KẾT THÚC THAY ĐỔI <<<

        // --- CỘT 4: Đến mục tiêu ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Mục tiêu"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: distanceToTarget >= 0 ? distanceToTarget.toFixed(0) + " m" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }

        // --- CỘT 5: Góc Pitch ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Pitch"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: _activeVehicle ? _activeVehicle.pitch.value.toFixed(1) + "°" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }

        // --- CỘT 6: Góc Roll ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("Roll"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: _activeVehicle ? _activeVehicle.roll.value.toFixed(1) + "°" : "--"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }

        // --- CỘT 7: Thời gian bay ---
        ColumnLayout {
            spacing: _margins / 4
            QGCLabel { text: qsTr("T.gian bay"); color: "lightgrey"; Layout.alignment: Qt.AlignHCenter }
            QGCLabel { text: _activeVehicle ? formatTime(_activeVehicle.flightTime) : "00:00:00"; font.bold: true; color: "white"; Layout.alignment: Qt.AlignHCenter }
        }
    }

    // Hàm formatTime vẫn được giữ lại để sử dụng
    function formatTime(totalSeconds) {
        if (isNaN(totalSeconds)) return "00:00:00";
        var hours   = Math.floor(totalSeconds / 3600);
        var minutes = Math.floor((totalSeconds - (hours * 3600)) / 60);
        var seconds = Math.floor(totalSeconds - (hours * 3600) - (minutes * 60));
        if (hours   < 10) { hours   = "0" + hours; }
        if (minutes < 10) { minutes = "0" + minutes; }
        if (seconds < 10) { seconds = "0" + seconds; }
        return hours + ':' + minutes + ':' + seconds;
    }
}
