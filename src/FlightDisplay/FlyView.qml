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
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.UTMSP
import QGroundControl.Viewer3D

Item {
    id: _root

    //---------- MILITARY COLOR PALETTE ----------
    readonly property color militaryBgPrimary:      "#0d0d0d"
    readonly property color militaryBgSecondary:    "#1a1a1a"
    readonly property color militaryBgPanel:        "#1f1f1f"
    readonly property color militaryAccentRed:      "#ff0000"
    readonly property color militaryAccentBlue:     "#00bfff"
    readonly property color militaryAccentGreen:    "#00ff00"
    readonly property color militaryTextPrimary:    "#ffffff"
    readonly property color militaryTextSecondary:  "#e0e0e0"
    readonly property color militaryBorder:         "#333333"
    readonly property color militaryWarning:        "#ffaa00"
    //--------------------------------------------

    property bool isSettingHome: false

    // Các property gốc
    property var planController:    _planController
    property var guidedController:  _guidedController
    property bool utmspSendActTrigger: false
    PlanMasterController { id: _planController; flyView: true; Component.onCompleted: start() }
    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl
    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    function dropMainStatusIndicatorTool() {
        toolbar.dropMainStatusIndicatorTool();
    }

    // Dark background overlay
    Rectangle {
        anchors.fill: parent
        color: militaryBgPrimary
        z: -1
    }

    QGCToolInsets { id: _toolInsets; leftEdgeBottomInset: _pipView.leftEdgeBottomInset; bottomEdgeLeftInset: _pipView.bottomEdgeLeftInset }
    FlyViewToolBar { id: toolbar; visible: !QGroundControl.videoManager.fullScreen }

    Item {
        id:                 mapHolder
        anchors.top:        toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap { id: mapControl; planMasterController: _planController; rightPanelWidth: ScreenTools.defaultFontPixelHeight * 9; pipView: _pipView; pipMode: !_mainWindowIsMap; toolInsets: customOverlay.totalToolInsets; mapName: "FlightDisplayView"; enabled: !viewer3DWindow.isOpen }
        FlyViewVideo { id: videoControl; pipView: _pipView }
        PipView {
            id: _pipView
            visible: false  // ẨN VIDEO FEED MẶC ĐỊNH
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1: mapControl
            item2: QGroundControl.videoManager.hasVideo ? videoControl : null
            show: false  // ẨN LUÔN
            z: QGroundControl.zOrderWidgets
            property real leftEdgeBottomInset: 0
            property real bottomEdgeLeftInset: 0
        }
        /*
        //---------- ATTITUDE INDICATOR (ARTIFICIAL HORIZON) - MOVED TO RIGHT ----------
        Rectangle {
            id: attitudeIndicator
            anchors.right: parent.right  // Đổi từ left sang right
            anchors.top: parent.top
            anchors.margins: _toolsMargin * 2
            width: ScreenTools.defaultFontPixelHeight * 15
            height: width
            color: militaryBgPanel
            border.color: militaryAccentBlue
            border.width: 3
            radius: 8
            z: QGroundControl.zOrderWidgets

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.color: militaryAccentBlue
                border.width: 1
                radius: parent.radius + 2
                opacity: 0.3
                z: -1
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                color: "transparent"
                border.color: militaryAccentBlue
                border.width: 1
                radius: parent.radius + 4
                opacity: 0.1
                z: -2
            }

            Item {
                id: horizonClip
                anchors.fill: parent
                anchors.margins: 10
                clip: true

                Rectangle {
                    id: horizon
                    width: parent.width * 2
                    height: parent.height * 2
                    anchors.centerIn: parent

                    rotation: _activeVehicle ? -_activeVehicle.roll.value : 0

                    transform: Translate {
                        y: _activeVehicle ? _activeVehicle.pitch.value * 2 : 0
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height / 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#004080" }
                            GradientStop { position: 1.0; color: "#0066cc" }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height / 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#4d3319" }
                            GradientStop { position: 1.0; color: "#2d1f0f" }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 2
                        color: militaryTextPrimary
                    }

                    Repeater {
                        model: [-30, -20, -10, 10, 20, 30]

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height / 2 - modelData * 2
                            spacing: 5

                            Rectangle {
                                width: 30
                                height: 2
                                color: militaryTextPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            QGCLabel {
                                text: Math.abs(modelData)
                                font.pointSize: ScreenTools.smallFontPointSize
                                font.family: "Monospace"
                                color: militaryTextPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 30
                                height: 2
                                color: militaryTextPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    width: 80
                    height: 80

                    Rectangle {
                        anchors.centerIn: parent
                        width: 60
                        height: 3
                        color: militaryAccentRed
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: militaryAccentRed
                        border.color: militaryTextPrimary
                        border.width: 1
                    }
                }
            }

            Canvas {
                id: rollCanvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var centerX = width / 2;
                    var centerY = height / 2;
                    var radius = Math.min(width, height) / 2 - 20;

                    ctx.strokeStyle = militaryTextSecondary;
                    ctx.lineWidth = 2;

                    for (var angle = -60; angle <= 60; angle += 10) {
                        var rad = (angle - 90) * Math.PI / 180;
                        var startRadius = radius - (angle % 30 === 0 ? 15 : 10);

                        ctx.beginPath();
                        ctx.moveTo(centerX + startRadius * Math.cos(rad), centerY + startRadius * Math.sin(rad));
                        ctx.lineTo(centerX + radius * Math.cos(rad), centerY + radius * Math.sin(rad));
                        ctx.stroke();
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10
                width: 0
                height: 0

                Canvas {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    rotation: _activeVehicle ? -_activeVehicle.roll.value : 0

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = militaryAccentRed;

                        ctx.beginPath();
                        ctx.moveTo(width / 2, 0);
                        ctx.lineTo(width / 2 - 8, height);
                        ctx.lineTo(width / 2 + 8, height);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -15
                width: ScreenTools.defaultFontPixelWidth * 8
                height: ScreenTools.defaultFontPixelHeight * 1.5
                color: militaryBgSecondary
                border.color: militaryAccentBlue
                border.width: 2
                radius: 4

                QGCLabel {
                    anchors.centerIn: parent
                    text: _activeVehicle ? Math.round(_activeVehicle.heading.value) + "°" : "---°"
                    font.bold: true
                    font.family: "Monospace"
                    color: militaryAccentBlue
                }
            }

            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: qsTr("ARTIFICIAL HORIZON")
                font.pointSize: ScreenTools.smallFontPointSize
                font.family: "Monospace"
                color: militaryTextSecondary
            }
        }
        */
        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.fill:           parent
            z:                      _fullItemZorder + 2
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            visible:                !QGroundControl.videoManager.fullScreen
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen

            onSetHomeModeToggled: {
                _root.isSettingHome = !_root.isSettingHome;
            }

            Rectangle {
                id: uavMessageContainer
                anchors.top: toolbar.bottom
                anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
                anchors.right: parent.right
                anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                width: uavMessageLabel.implicitWidth + (_margins * 4)
                height: uavMessageLabel.implicitHeight + (_margins * 2)
                color: Qt.rgba(0.8, 0, 0, 0.9)
                border.color: militaryAccentRed
                border.width: 3
                radius: 8
                z: QGroundControl.zOrderWidgets
                visible: uavMessageLabel.text !== ""

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    color: "transparent"
                    border.color: militaryAccentRed
                    border.width: 2
                    radius: parent.radius + 2
                    opacity: 0.4
                    z: -1
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -8
                    color: "transparent"
                    border.color: militaryAccentRed
                    border.width: 1
                    radius: parent.radius + 4
                    opacity: 0.2
                    z: -2
                }

                QGCLabel {
                    id: uavMessageLabel
                    anchors.centerIn: parent
                    font.pointSize: ScreenTools.defaultFontPointSize * 2
                    font.bold: true
                    font.family: "Monospace"
                    color: militaryTextPrimary
                    text: ""

                    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

                    Connections {
                        target: _activeVehicle
                        ignoreUnknownSignals: true

                        function onUavInfoReceived(boardStatus, message) {
                            if (message) {
                                uavMessageLabel.text = message
                            }
                        }
                    }

                    Timer {
                        id: hideMessageTimer
                        interval: 5000
                        running: uavMessageLabel.text !== ""
                        repeat: false
                        onTriggered: {
                            uavMessageLabel.text = ""
                        }
                    }

                    onTextChanged: {
                        if (text !== "") {
                            hideMessageTimer.restart()
                        }
                    }
                }
            }
        }

        FlyViewCustomLayer { id: customOverlay; anchors.fill: widgetLayer; z: _fullItemZorder + 2; parentToolInsets: widgetLayer.totalToolInsets; mapControl: _mapControl; visible: !QGroundControl.videoManager.fullScreen }
        FlyViewInsetViewer { id: widgetLayerInsetViewer; anchors.fill: parent; z: widgetLayer.z + 1; insetsToView: widgetLayer.totalToolInsets; visible: false }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            enabled: _root.isSettingHome

            onClicked: (mouse) => {
                var coord = mapControl.toCoordinate(Qt.point(mouse.x, mouse.y), false);
                var dialog = setHomeConfirmationDialogComponent.createObject(_root, { "selectedCoordinate": coord });
                dialog.open();
            }
        }

        GuidedActionsController { id: guidedActionsController; missionController: _missionController; guidedValueSlider: _guidedValueSlider }
        GuidedValueSlider { id: guidedValueSlider; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; z: QGroundControl.zOrderTopMost; visible: false }
        Viewer3D { id: viewer3DWindow; anchors.fill: parent }
    }

    UTMSPActivationStatusBar {
        activationStartTimestamp:   UTMSPStateStorage.startTimeStamp
        activationApproval:         UTMSPStateStorage.showActivationTab && QGroundControl.utmspManager.utmspVehicle.vehicleActivation
        flightID:                   UTMSPStateStorage.flightID
        anchors.fill:               parent

        function onActivationTriggered(value) {
            _root.utmspSendActTrigger = value
        }
    }

    Component {
        id: setHomeConfirmationDialogComponent

        Dialog {
            property var selectedCoordinate

            standardButtons: Dialog.NoButton
            parent: Overlay.overlay
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            width: ScreenTools.defaultFontPixelWidth * 40
            implicitHeight: contentColumn.implicitHeight

            background: Rectangle {
                color: militaryBgPanel
                border.color: militaryAccentBlue
                border.width: 3
                radius: 8

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    color: "transparent"
                    border.color: militaryAccentBlue
                    border.width: 2
                    radius: parent.radius + 2
                    opacity: 0.3
                    z: -1
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -8
                    color: "transparent"
                    border.color: militaryAccentBlue
                    border.width: 1
                    radius: parent.radius + 4
                    opacity: 0.1
                    z: -2
                }
            }

            contentItem: ColumnLayout {
                id:         contentColumn
                width: parent.width
                spacing:    ScreenTools.defaultFontPixelWidth

                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 2.5
                    color: militaryBgSecondary
                    border.color: militaryAccentRed
                    border.width: 2
                    radius: 4

                    Row {
                        anchors.centerIn: parent
                        spacing: _margins

                        QGCLabel {
                            text: "⚠"
                            font.pointSize: ScreenTools.largeFontPointSize
                            color: militaryAccentRed
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCLabel {
                            text: qsTr("XÁC NHẬN ĐẶT VỊ TRÍ")
                            font.pointSize: ScreenTools.largeFontPointSize
                            font.bold: true
                            font.family: "Monospace"
                            color: militaryTextPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                QGCLabel {
                    Layout.fillWidth: true
                    Layout.topMargin: _margins
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Bạn có chắc chắn muốn đặt Vị trí hủy nhiệm vụ ở đây?")
                    wrapMode: Text.WordWrap
                    font.pointSize: ScreenTools.mediumFontPointSize
                    color: militaryTextPrimary
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: _margins
                    implicitHeight: coordLayout.implicitHeight + (_margins * 2)
                    color: militaryBgSecondary
                    border.color: militaryAccentBlue
                    border.width: 2
                    radius: 4

                    GridLayout {
                        id: coordLayout
                        anchors.fill: parent
                        anchors.margins: _margins
                        columns: 2
                        columnSpacing: ScreenTools.defaultFontPixelWidth
                        rowSpacing: _margins / 2

                        QGCLabel {
                            text: qsTr("📍 Vĩ độ:")
                            font.family: "Monospace"
                            color: militaryTextSecondary
                        }
                        QGCLabel {
                            text: selectedCoordinate.latitude.toFixed(7)
                            font.bold: true
                            font.family: "Monospace"
                            color: militaryAccentGreen
                            Layout.alignment: Qt.AlignRight
                        }

                        QGCLabel {
                            text: qsTr("📍 Kinh độ:")
                            font.family: "Monospace"
                            color: militaryTextSecondary
                        }
                        QGCLabel {
                            text: selectedCoordinate.longitude.toFixed(7)
                            font.bold: true
                            font.family: "Monospace"
                            color: militaryAccentGreen
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                DialogButtonBox {
                    Layout.fillWidth: true
                    Layout.topMargin: _margins * 2
                    background: Item {}

                    QGCButton {
                        text: qsTr("Hủy")
                        onClicked: reject()
                        DialogButtonBox.buttonRole: DialogButtonBox.RejectRole

                        background: Rectangle {
                            color: militaryBgSecondary
                            border.color: militaryBorder
                            border.width: 2
                            radius: 4
                        }
                    }
                    QGCButton {
                        text: qsTr("Xác nhận")
                        primary: true
                        onClicked: accept()
                        DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole

                        background: Rectangle {
                            color: militaryAccentRed
                            border.color: militaryAccentRed
                            border.width: 2
                            radius: 4
                        }
                    }
                }
            }

            onAccepted: {
                if (_activeVehicle) { _activeVehicle.doSetHome(selectedCoordinate); }
                _root.isSettingHome = false;
            }
            onRejected: {
                _root.isSettingHome = false;
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: toolbar.bottom
        anchors.topMargin: _margins

        width: instructionLabel.implicitWidth + (_margins * 4)
        height: instructionLabel.implicitHeight + (_margins * 2)

        color: Qt.rgba(0, 0.5, 0, 0.9)
        border.color: militaryAccentGreen
        border.width: 3
        radius: 8

        visible: isSettingHome
        z: QGroundControl.zOrderWidgets

        SequentialAnimation on opacity {
            running: isSettingHome
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.6; duration: 800 }
            NumberAnimation { from: 0.6; to: 1.0; duration: 800 }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            color: "transparent"
            border.color: militaryAccentGreen
            border.width: 2
            radius: parent.radius + 2
            opacity: 0.4
            z: -1
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            color: "transparent"
            border.color: militaryAccentGreen
            border.width: 1
            radius: parent.radius + 4
            opacity: 0.2
            z: -2
        }

        QGCLabel {
            id: instructionLabel
            anchors.centerIn: parent
            text: qsTr("Đang ở chế độ ĐẶT VỊ TRÍ HỦY NHIỆM VỤ: Nhấn vào bản đồ để chọn vị trí.")
            font.bold: true
            font.family: "Monospace"
            color: militaryTextPrimary
        }
    }
}
