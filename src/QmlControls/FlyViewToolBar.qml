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
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight * 1.4
    color:  Qt.rgba(0.5, 0.5, 0.5, 0.55)

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple

    // Data từ FlyViewWidgetLayer để hiển thị trạng thái ngòi
    property string currentBoardStatus: "Đang kết nối..."

    Connections {
        target: _activeVehicle
        ignoreUnknownSignals: true
        function onUavInfoReceived(boardStatus, message) {
            _root.currentBoardStatus = boardStatus
        }
    }

    QGCPalette { id: qgcPal }

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    // Top border
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        color: "white"
        opacity: 0.6
    }

    // Bottom border
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         2
        color:          "white"
        opacity:        0.4
    }

    //layout items
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.5
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.5
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: ScreenTools.defaultFontPixelWidth * 0.75

        //---------- 1. LOGO ----------
        Rectangle {
            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.alignment: Qt.AlignVCenter
            color: Qt.rgba(0.5, 0.5, 0.5, 0.15)
            border.color: "white"
            border.width: 2
            radius: 8

            Image {
                id: customLogo
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                source: "qrc:/res/QGCLogoFull.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mainWindow.showToolSelectDialog()
            }
        }

        //---------- 2. VIEW TABS ----------
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: ScreenTools.defaultFontPixelWidth * 0.5

            component ViewTab: Rectangle {
                property string tabText: ""
                property string tabIcon: ""
                property bool isActive: false
                property string viewName: ""
                signal clicked()

                width: ScreenTools.defaultFontPixelWidth * 14
                height: ScreenTools.defaultFontPixelHeight * 3.5
                color: isActive ? Qt.rgba(0, 0.75, 1, 0.25) : Qt.rgba(0.5, 0.5, 0.5, 0.55)
                border.color: isActive ? "#00ff00" : "white"
                border.width: isActive ? 2 : 1
                radius: 6

                Row {
                    anchors.centerIn: parent
                    spacing: 2

                    QGCLabel {
                        text: tabIcon
                        font.pointSize: ScreenTools.mediumFontPointSize * 1.2
                        visible: tabIcon !== ""
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    QGCLabel {
                        text: tabText
                        color: "white"
                        font.bold: true
                        font.family: "Monospace"
                        font.pointSize: ScreenTools.defaultFontPointSize
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.clicked()
                }
            }

            ViewTab {
                tabText: "LẬP K.H"
                isActive: false
                onClicked: {
                    if (mainWindow.allowViewSwitch()) {
                        mainWindow.showPlanView()
                    }
                }
            }
        }

        //---------- 3. ĐỒNG HỒ ----------
        Rectangle {
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.alignment: Qt.AlignVCenter
            color: Qt.rgba(0.5, 0.5, 0.5, 0.35)
            border.color: "white"
            border.width: 2
            radius: 6

            Column {
                anchors.centerIn: parent
                spacing: 2

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    QGCLabel {
                        id: timeLabel
                        text: Qt.formatTime(new Date(), "hh:mm:ss")
                        color: "white"
                        font.bold: true
                        font.family: "Monospace"
                        font.pointSize: ScreenTools.defaultFontPointSize * 1.3
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                QGCLabel {
                    id: dateLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                    color: "white"
                    font.family: "Monospace"
                    font.pointSize: ScreenTools.smallFontPointSize * 1.1
                }
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var currentTime = new Date()
                    timeLabel.text = Qt.formatTime(currentTime, "hh:mm:ss")
                    dateLabel.text = Qt.formatDate(currentTime, "dd/MM/yyyy")
                }
            }
        }

        //---------- 4. CONNECTION STATUS ----------
        Rectangle {
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.alignment: Qt.AlignVCenter
            color: getStatusBGColor()
            border.color: getStatusBorderColor()
            border.width: 2
            radius: 6
            visible: _activeVehicle

            function getStatusBGColor() {
                if (!_activeVehicle) return Qt.rgba(0.5, 0, 0, 0.3);
                if (_communicationLost) return Qt.rgba(0.5, 0, 0, 0.3);
                if (_activeVehicle.armed) return Qt.rgba(0, 0.8, 0, 0.2);
                return Qt.rgba(0.8, 0.8, 0, 0.2);
            }

            function getStatusBorderColor() {
                if (!_activeVehicle || _communicationLost) return "#ff0000";
                if (_activeVehicle.armed) return "#00ff00";
                return "#ffff00";
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: parent.parent.getStatusBorderColor()
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                        NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                    }
                }

                QGCLabel {
                    text: {
                        if (!_activeVehicle) return "KO P.TIỆN";
                        if (_communicationLost) return "MẤT K.NỐI";
                        if (_activeVehicle.armed) {
                            if (_activeVehicle.flying) return "ĐANG BAY";
                            return "ĐÃ K.ĐỘNG";
                        }
                        return "TẮT Đ.CƠ";
                    }
                    color: "#ffffff"
                    font.bold: true
                    font.family: "Monospace"
                    font.pointSize: ScreenTools.smallFontPointSize * 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: dropMainStatusIndicatorTool()
            }
        }

        //---------- 5. FLIGHT MODE ----------
        Rectangle {
            id: flightModeButton
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.alignment: Qt.AlignVCenter
            color: flightModeMouseArea.containsMouse ? Qt.rgba(0.2, 0.6, 0.9, 0.5) : Qt.rgba(0.1, 0.5, 0.8, 0.2)
            border.color: "white"
            border.width: 2
            radius: 6
            visible: _activeVehicle

            Row {
                anchors.centerIn: parent
                spacing: 6

                QGCLabel {
                    text: _activeVehicle ? _activeVehicle.flightMode : "KO XĐ"
                    color: "white"
                    font.bold: true
                    font.family: "Monospace"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                QGCLabel {
                    text: "▼"
                    color: "white"
                    font.pointSize: ScreenTools.smallFontPointSize
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: flightModeMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: flightModeMenu.open()
            }

            Menu {
                id: flightModeMenu
                y: parent.height

                background: Rectangle {
                    implicitWidth: ScreenTools.defaultFontPixelWidth * 18
                    color: Qt.rgba(0.1, 0.1, 0.1, 0.95)
                    border.color: "white"
                    border.width: 2
                    radius: 6
                }

                Repeater {
                    model: _activeVehicle ? _activeVehicle.flightModes : []

                    MenuItem {
                        text: modelData
                        height: ScreenTools.defaultFontPixelHeight * 2.5

                        background: Rectangle {
                            color: parent.hovered ? Qt.rgba(0, 0.75, 1, 0.3) : "transparent"
                            radius: 4
                        }

                        contentItem: Row {
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "#00ff00"
                                anchors.verticalCenter: parent.verticalCenter
                                visible: _activeVehicle && _activeVehicle.flightMode === modelData
                            }

                            QGCLabel {
                                text: modelData
                                color: parent.parent.hovered ? "#00ff00" : "white"
                                font.bold: _activeVehicle && _activeVehicle.flightMode === modelData
                                font.family: "Monospace"
                                font.pointSize: ScreenTools.defaultFontPointSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onTriggered: {
                            if (_activeVehicle) {
                                _activeVehicle.flightMode = modelData
                            }
                        }
                    }
                }

                MenuSeparator {
                    contentItem: Rectangle {
                        implicitHeight: 1
                        color: "white"
                        opacity: 0.5
                    }
                }

                MenuItem {
                    text: "Hủy bỏ"
                    height: ScreenTools.defaultFontPixelHeight * 2.5

                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(0.8, 0, 0, 0.3) : "transparent"
                        radius: 4
                    }

                    contentItem: QGCLabel {
                        text: "Hủy bỏ"
                        color: parent.hovered ? "#ff0000" : "#888888"
                        font.family: "Monospace"
                        font.pointSize: ScreenTools.defaultFontPointSize
                        horizontalAlignment: Text.AlignHCenter
                    }

                    onTriggered: flightModeMenu.close()
                }
            }
        }

        //---------- 6. GPS STATUS ----------
                // Custom GPS button với popup gốc
                Rectangle {
                    id: customGPSButton
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 13
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
                    Layout.alignment: Qt.AlignVCenter
                    color: Qt.rgba(0.1, 0.8, 0.1, 0.15)
                    border.color: getGPSColor()
                    border.width: 2
                    radius: 6
                    visible: _activeVehicle

                    function getGPSColor() {
                        if (!_activeVehicle) return "#888888";
                        var satCount = _activeVehicle.gps.count.rawValue;
                        if (satCount >= 10) return "#00ff00";
                        if (satCount >= 6) return "#ffff00";
                        return "#ff0000";
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        QGCLabel {
                            text: "GPS"
                            color: "white"
                            font.family: "Monospace"
                            font.pointSize: ScreenTools.smallFontPointSize
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCLabel {
                            text: _activeVehicle ? _activeVehicle.gps.count.rawValue.toString() : "0"
                            color: "white"
                            font.bold: true
                            font.family: "Monospace"
                            font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Gọi popup GPS gốc của QGC
                            mainWindow.showIndicatorDrawer(gpsIndicatorPageComponent, customGPSButton)
                        }
                    }

                    // Component cho GPS Indicator Page
                    Component {
                        id: gpsIndicatorPageComponent
                        GPSIndicatorPage { }
                    }
                }

        //---------- 7. BATTERY STATUS - CẢI TIẾN ----------
        Item {
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.alignment: Qt.AlignVCenter
            visible: _activeVehicle

            Row {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: _activeVehicle ? _activeVehicle.batteries : 0

                    Rectangle {
                        width: parent.parent.width
                        height: parent.parent.height
                        color: Qt.rgba(0.2, 0.2, 0.2, 0.3)
                        border.color: getBatteryColor()
                        border.width: 2
                        radius: 6

                        property var battery: object

                        function getBatteryColor() {
                            if (!battery) return "#888888";
                            var percent = battery.percentRemaining.rawValue;
                            if (isNaN(percent)) return "#888888";
                            if (percent > 50) return "#00ff00";
                            if (percent > 20) return "#ffff00";
                            return "#ff0000";
                        }

                        // Layout cân đối với grid thay vì Column/Row lồng nhau
                        Column {
                            anchors.centerIn: parent
                            spacing: 3

                            // Dòng 1: Phần trăm pin (to, đậm)
                            QGCLabel {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    if (!battery) return "N/A";
                                    var percent = battery.percentRemaining.rawValue;
                                    if (isNaN(percent)) {
                                        var voltage = battery.voltage.rawValue;
                                        return isNaN(voltage) ? "N/A" : voltage.toFixed(1) + "V";
                                    }
                                    return percent > 98.9 ? "100%" : percent.toFixed(0) + "%";
                                }
                                color: "white"
                                font.bold: true
                                font.family: "Monospace"
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.2
                            }

                            // Dòng 2: Voltage và Current (nhỏ hơn, cùng size)
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8

                                QGCLabel {
                                    text: {
                                        if (!battery) return "?V";
                                        var v = battery.voltage.rawValue;
                                        return isNaN(v) ? "?V" : v.toFixed(1) + "V";
                                    }
                                    color: "white"
                                    font.family: "Monospace"
                                    font.pointSize: ScreenTools.smallFontPointSize * 1.0
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 1
                                    height: 12
                                    color: "#666666"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                QGCLabel {
                                    text: {
                                        if (!battery || !battery.current) return "?A";
                                        var c = battery.current.rawValue;
                                        return isNaN(c) ? "?A" : c.toFixed(1) + "A";
                                    }
                                    color: "white"
                                    font.family: "Monospace"
                                    font.pointSize: ScreenTools.smallFontPointSize * 1.0
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }


        //---------- SPACER - ĐẨY NGÒI SANG PHẢI ----------
        Item {
            Layout.fillWidth: true
        }

        //---------- 8. TRẠNG THÁI NGÒI (GÓCC PHẢI) ----------
        Rectangle {
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 18
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.5
            Layout.alignment: Qt.AlignVCenter
            color: currentBoardStatus === "True" ? Qt.rgba(1, 0, 0, 0.25) : Qt.rgba(0, 0.5, 0, 0.2)
            border.color: currentBoardStatus === "True" ? "#ff0000" : "#00ff00"
            border.width: 3
            radius: 6
            visible: _activeVehicle

            SequentialAnimation on border.color {
                running: currentBoardStatus === "True"
                loops: Animation.Infinite
                ColorAnimation { from: "#ff0000"; to: "#ff6666"; duration: 400 }
                ColorAnimation { from: "#ff6666"; to: "#ff0000"; duration: 400 }
            }

            Row {
                anchors.centerIn: parent
                spacing: 6

                QGCLabel {
                    text: {
                        if (currentBoardStatus === "True") return "NGÒI MỞ";
                        else if (currentBoardStatus === "False") return "AN TOÀN";
                        else return "CHƯA MỞ NGÒI";
                    }
                    color: parent.parent.border.color
                    font.bold: true
                    font.family: "Monospace"
                    font.pointSize: ScreenTools.smallFontPointSize * 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Show ngòi detail dialog if needed
                }
            }
        }
    }

    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          "#00ff00"
        visible:        !largeProgressBar.visible
    }

    // Large parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
            color:          "#00ff00"
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               "Đang tải xuống"
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               "Nhấn vào đâu đó để ẩn"

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }
}
