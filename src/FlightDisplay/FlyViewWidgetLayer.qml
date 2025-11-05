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


// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    signal setHomeModeToggled

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen:         false

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    property bool utmspActTrigger

    // Data properties for telemetry - AT ROOT LEVEL
    property string currentBoardStatus: "Đang kết nối..."
    property var flightTimeFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("FlightTime") : null
    property var pitchFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("Pitch") : null
    property var rollFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("Roll") : null
    property var airSpeedFact: (_activeVehicle && _activeVehicle.vehicle) ? _activeVehicle.vehicle.getFact("AirSpeed") : null

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

    Connections {
        target: _activeVehicle
        ignoreUnknownSignals: true
        function onUavInfoReceived(boardStatus, message) {
            _root.currentBoardStatus = boardStatus
        }
    }

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       0
        leftEdgeCenterInset:    0
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : (horizontalToolStrip.visible ? ScreenTools.defaultFontPixelHeight * 5 : parentToolInsets.leftEdgeBottomInset)
        rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
        rightEdgeCenterInset:   topRightPanel.rightEdgeCenterInset
        rightEdgeBottomInset:   0
        topEdgeLeftInset:       0
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightPanel.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  0
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : 0
    }

    FlyViewTopRightPanel {
        id:                     topRightPanel
        anchors.top:            parent.top
        anchors.right:          parent.right
        anchors.topMargin:      _layoutMargin
        anchors.rightMargin:    _layoutMargin
        maximumHeight:          parent.height - (_margins * 5)

        property real topEdgeRightInset:    height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.margins:    _layoutMargin
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:           !topRightPanel.visible

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.margins:    _layoutMargin
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:            false

        property real bottomEdgeRightInset:     0
        property real bottomEdgeCenterInset:    0
        property real rightEdgeBottomInset:     0
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
        utmspSliderTrigger:         utmspActTrigger
    }

    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        _layoutMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         _layoutMargin
        source:                     "qrc:/qml/QGroundControl/FlightDisplay/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                               ScreenTools.defaultFontPixelHeight * 6

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x
        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined
        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    // ẨN TOOLSTRIP DỌC
    FlyViewToolStrip {
        id:                     toolStrip
        visible:                false

        property real topEdgeLeftInset:     0
        property real leftEdgeTopInset:     0
        property real leftEdgeCenterInset:  0

        onDisplayPreFlightChecklist: {
            if (!preFlightChecklistLoader.active) {
                preFlightChecklistLoader.active = true
            }
            preFlightChecklistLoader.item.open()
        }

        onSetHomeModeToggled: _root.setHomeModeToggled()
    }

    // HORIZONTAL TOOLSTRIP - NGANG HÀNG VỚI VIDEO (BỎ NÚT CAMERA)
    Row {
        id:                     horizontalToolStrip
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:            parent.top
        anchors.topMargin:      _layoutMargin
        spacing:                _margins * 2
        z:                      QGroundControl.zOrderWidgets
        visible:                !QGroundControl.videoManager.fullScreen

        // Military styled button component
        component MilitaryButton: QGCButton {
            property string buttonText: ""
            property string buttonIcon: ""

            width:  ScreenTools.defaultFontPixelWidth * 10
            height: ScreenTools.defaultFontPixelHeight * 3

            background: Rectangle {
                color: Qt.rgba(0.1, 0.1, 0.1, 0.9)
                border.color: parent.hovered ? "#00ff00" : "#00bfff"
                border.width: 2
                radius: 6

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    color: "transparent"
                    border.color: parent.parent.border.color
                    border.width: 1
                    radius: parent.radius + 1
                    opacity: 0.3
                    z: -1
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 2

                QGCLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: buttonIcon
                    font.pointSize: ScreenTools.mediumFontPointSize
                    visible: buttonIcon !== ""
                }

                QGCLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: buttonText
                    color: "#00bfff"
                    font.bold: true
                    font.family: "Monospace"
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }
        }

        MilitaryButton {
            buttonText: qsTr("TAKEOFF")
            buttonIcon: "🚁"
            visible: _activeVehicle && _activeVehicle.guidedModeSupported && !_activeVehicle.flying
            onClicked: {
                _guidedController.confirmAction(_guidedController.actionTakeoff)
            }
        }

        MilitaryButton {
            buttonText: qsTr("LAND")
            buttonIcon: "🛬"
            visible: _activeVehicle && _activeVehicle.guidedModeSupported && _activeVehicle.flying
            onClicked: {
                _guidedController.confirmAction(_guidedController.actionLand)
            }
        }

        MilitaryButton {
            buttonText: qsTr("RTL")
            buttonIcon: "🏠"
            visible: _activeVehicle && _activeVehicle.guidedModeSupported
            onClicked: {
                _guidedController.confirmAction(_guidedController.actionRTL)
            }
        }

        MilitaryButton {
            buttonText: qsTr("SET HOME")
            buttonIcon: "📍"
            visible: _activeVehicle
            onClicked: {
                _root.setHomeModeToggled()
            }
        }

        MilitaryButton {
            buttonText: qsTr("CHECK")
            buttonIcon: "✓"
            onClicked: {
                if (!preFlightChecklistLoader.active) {
                    preFlightChecklistLoader.active = true
                }
                preFlightChecklistLoader.item.open()
            }
        }
    }

    GripperMenu {
        id: gripperOptions
    }

    //---------- LEFT BAR: VIDEO FEED + 2 METRICS ----------
    Column {
        id: leftPanelContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: _layoutMargin
        width: ScreenTools.defaultFontPixelWidth * 60  // GẤP RƯỠI (40 → 60)
        spacing: _layoutMargin
        z: QGroundControl.zOrderWidgets

        // VIDEO FEED - RỘNG HỚN, THẤP HƠN
        Rectangle {
            id: videoFeedContainer
            width: parent.width
            height: ScreenTools.defaultFontPixelHeight * 15
            color: Qt.rgba(0, 0, 0, 0.9)
            border.color: "#00bfff"
            border.width: 3
            radius: 8
            visible: QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.color: "#00bfff"
                border.width: 1
                radius: parent.radius + 2
                opacity: 0.3
                z: -1
            }

            QGCLabel {
                anchors.centerIn: parent
                text: qsTr("📹 VIDEO FEED\n(Waiting for video)")
                font.bold: true
                font.family: "Monospace"
                color: "#00bfff"
                horizontalAlignment: Text.AlignHCenter
                visible: !QGroundControl.videoManager.videoRunning
            }

            QGCLabel {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 5
                text: qsTr("📹 LIVE")
                font.bold: true
                font.family: "Monospace"
                font.pointSize: ScreenTools.smallFontPointSize
                color: "#ff0000"
                visible: QGroundControl.videoManager.videoRunning

                SequentialAnimation on opacity {
                    running: QGroundControl.videoManager.videoRunning
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: 500 }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 500 }
                }
            }
        }

        // 2 METRICS: GIÓ & QUÃNG ĐƯỜNG
        component CompactMetric: Rectangle {
            property string label: ""
            property string value: "--"
            property string unit: ""
            property color valueColor: "#00ff00"
            property string icon: ""

            width: parent.width
            height: ScreenTools.defaultFontPixelHeight * 3
            color: Qt.rgba(0.05, 0.05, 0.05, 0.98)
            border.color: valueColor
            border.width: 2
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2
                    Layout.fillHeight: true
                    color: Qt.rgba(0.1, 0.1, 0.1, 0.5)
                    border.color: valueColor
                    border.width: 1
                    radius: 4

                    QGCLabel {
                        anchors.centerIn: parent
                        text: icon
                        font.pointSize: ScreenTools.largeFontPointSize
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    QGCLabel {
                        text: label
                        color: "#888888"
                        font.pointSize: ScreenTools.smallFontPointSize - 1
                        font.family: "Monospace"
                    }

                    QGCLabel {
                        text: value + (unit !== "" ? " " + unit : "")
                        color: valueColor
                        font.bold: true
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.family: "Monospace"
                    }
                }
            }
        }

        CompactMetric {
            label: "GIÓ"
            icon: "💨"
            value: _root.airSpeedFact ? _root.airSpeedFact.valueString : "--"
            unit: _root.airSpeedFact ? _root.airSpeedFact.units : ""
            valueColor: "#00bfff"
        }

        CompactMetric {
            label: "QUÃNG ĐƯỜNG"
            icon: "📏"
            value: (_activeVehicle && _activeVehicle.flightDistance) ? _activeVehicle.flightDistance.valueString : "--"
            unit: (_activeVehicle && _activeVehicle.flightDistance) ? _activeVehicle.flightDistance.units : ""
            valueColor: "#00ff00"
        }
    }

    //---------- BOTTOM BAR: 4 MAIN METRICS ----------
    Row {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: _layoutMargin
        width: parent.width * 0.6
        height: ScreenTools.defaultFontPixelHeight * 5
        spacing: _layoutMargin
        z: QGroundControl.zOrderWidgets
        visible: _activeVehicle

        component BottomMetric: Rectangle {
            property string label: ""
            property string value: "--"
            property string unit: ""
            property color valueColor: "#00ff00"
            property string icon: ""

            width: (parent.width - _layoutMargin * 3) / 4
            height: parent.height
            color: Qt.rgba(0.05, 0.05, 0.05, 0.95)
            border.color: valueColor
            border.width: 2
            radius: 6

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    QGCLabel {
                        text: icon
                        font.pointSize: ScreenTools.smallFontPointSize
                        visible: icon !== ""
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    QGCLabel {
                        text: label
                        color: "#888888"
                        font.pointSize: ScreenTools.smallFontPointSize - 1
                        font.family: "Monospace"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                QGCLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: value + (unit !== "" ? " " + unit : "")
                    color: valueColor
                    font.bold: true
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.family: "Monospace"
                }
            }
        }

        BottomMetric {
            label: "TỐC ĐỘ"
            icon: "➡"
            value: (_activeVehicle && _activeVehicle.groundSpeed) ? _activeVehicle.groundSpeed.valueString : "--"
            unit: (_activeVehicle && _activeVehicle.groundSpeed) ? _activeVehicle.groundSpeed.units : ""
            valueColor: "#00ff00"
        }

        BottomMetric {
            label: "ĐỘ CAO"
            icon: "⬆"
            value: (_activeVehicle && _activeVehicle.altitudeAMSL) ? _activeVehicle.altitudeAMSL.valueString : "--"
            unit: (_activeVehicle && _activeVehicle.altitudeRelative) ? _activeVehicle.altitudeRelative.units : ""
            valueColor: "#ffaa00"
        }

        BottomMetric {
            label: "MỤC TIÊU"
            icon: "🎯"
            value: _root.distanceToTarget >= 0 ? _root.distanceToTarget.toFixed(0) : "--"
            unit: "m"
            valueColor: "#ff00ff"
        }

        BottomMetric {
            label: "THỜI GIAN BAY"
            icon: "⏱"
            value: _root.flightTimeFact ? _root.flightTimeFact.valueString : "00:00:00"
            unit: ""
            valueColor: "#00bfff"
        }
    }

    //---------- RIGHT BAR: ARTIFICIAL HORIZON + COMPASS + PITCH + ROLL ----------
    Column {
        id: rightInstrumentColumn
        anchors.right: parent.right
        anchors.rightMargin: _layoutMargin
        anchors.top: parent.top
        // anchors.topMargin: ScreenTools.toolbarHeight * 1.4 + _layoutMargin
        width: ScreenTools.defaultFontPixelWidth * 18
        spacing: _layoutMargin
        z: QGroundControl.zOrderWidgets

        // ARTIFICIAL HORIZON (THAM KHẢO TỪ FLYVIEW)
        Rectangle {
            id: attitudeIndicator
            width: parent.width
            height: width
            color: Qt.rgba(0, 0, 0, 0.9)
            border.color: "#00bfff"
            border.width: 3
            radius: 8

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.color: "#00bfff"
                border.width: 1
                radius: parent.radius + 2
                opacity: 0.3
                z: -1
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
                        color: "#ffffff"
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
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            QGCLabel {
                                text: Math.abs(modelData)
                                font.pointSize: ScreenTools.smallFontPointSize
                                font.family: "Monospace"
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 30
                                height: 2
                                color: "#ffffff"
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
                        color: "#ff0000"
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: "#ff0000"
                        border.color: "#ffffff"
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

                    ctx.strokeStyle = "#e0e0e0";
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
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -ScreenTools.defaultFontPixelHeight * 1.5
                width: ScreenTools.defaultFontPixelWidth * 15
                height: ScreenTools.defaultFontPixelHeight * 1.2
                color: Qt.rgba(0, 0.75, 1, 0.2)
                border.color: "#00bfff"
                border.width: 2
                radius: 4

                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("ARTIFICIAL HORIZON")
                    color: "#00bfff"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize - 2
                    font.family: "Monospace"
                }
            }
        }

        // COMPASS
        Rectangle {
            id: compassContainer
            width: parent.width
            height: width
            color: Qt.rgba(0, 0, 0, 0.95)
            border.color: "#00bfff"
            border.width: 3
            radius: width / 2
            visible: _activeVehicle !== null

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.color: "#00bfff"
                border.width: 1
                radius: parent.radius + 2
                opacity: 0.3
                z: -1
            }

            Item {
                id: compassRose
                anchors.fill: parent
                anchors.margins: 12
                rotation: _activeVehicle ? -_activeVehicle.heading.rawValue : 0

                Behavior on rotation {
                    RotationAnimation {
                        duration: 250
                        direction: RotationAnimation.Shortest
                    }
                }

                QGCLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2
                    text: "N"
                    color: "#ff0000"
                    font.bold: true
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.family: "Monospace"
                }

                QGCLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width - width - 2
                    text: "E"
                    color: "#00bfff"
                    font.bold: true
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.family: "Monospace"
                }

                QGCLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - height - 2
                    text: "S"
                    color: "#00bfff"
                    font.bold: true
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.family: "Monospace"
                }

                QGCLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 2
                    text: "W"
                    color: "#00bfff"
                    font.bold: true
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.family: "Monospace"
                }

                Repeater {
                    model: 36
                    Rectangle {
                        property real angle: index * 10
                        property bool isMajor: index % 3 === 0
                        property real distance: parent.width / 2 - (isMajor ? 8 : 4)

                        x: parent.width / 2 + Math.cos((angle - 90) * Math.PI / 180) * distance - width / 2
                        y: parent.height / 2 + Math.sin((angle - 90) * Math.PI / 180) * distance - height / 2
                        width: isMajor ? 2 : 1
                        height: isMajor ? 8 : 4
                        color: "#00bfff"
                        opacity: isMajor ? 0.8 : 0.4
                        rotation: angle
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.35
                height: parent.height * 0.35
                color: Qt.rgba(0, 0, 0, 0.9)
                border.color: "#00ff00"
                border.width: 2
                radius: width / 2
                z: 100

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    QGCLabel {
                        Layout.alignment: Qt.AlignHCenter
                        text: _activeVehicle ? Math.round(_activeVehicle.heading.rawValue).toString() : "---"
                        color: "#00ff00"
                        font.bold: true
                        font.pointSize: ScreenTools.largeFontPointSize
                        font.family: "Monospace"
                    }

                    QGCLabel {
                        Layout.alignment: Qt.AlignHCenter
                        text: "°"
                        color: "#888888"
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.family: "Monospace"
                    }
                }
            }

            Canvas {
                id: northPointer
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                z: 50

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var centerX = width / 2;
                    var centerY = height / 2;
                    var pointerLength = height / 2 - 14;

                    ctx.beginPath();
                    ctx.moveTo(centerX, centerY - pointerLength);
                    ctx.lineTo(centerX - 6, centerY - pointerLength + 12);
                    ctx.lineTo(centerX + 6, centerY - pointerLength + 12);
                    ctx.closePath();

                    ctx.fillStyle = "#ff0000";
                    ctx.fill();
                    ctx.strokeStyle = "#ffffff";
                    ctx.lineWidth = 1;
                    ctx.stroke();
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -ScreenTools.defaultFontPixelHeight * 1.8
                width: ScreenTools.defaultFontPixelWidth * 12
                height: ScreenTools.defaultFontPixelHeight * 1.5
                color: Qt.rgba(0, 0.75, 1, 0.2)
                border.color: "#00bfff"
                border.width: 2
                radius: 4

                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("COMPASS")
                    color: "#00bfff"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                    font.family: "Monospace"
                }
            }
        }

        // PITCH
        Rectangle {
            width: parent.width
            height: ScreenTools.defaultFontPixelHeight * 4
            color: Qt.rgba(0.05, 0.05, 0.05, 0.98)
            border.color: "#00ff00"
            border.width: 2
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.5
                    Layout.fillHeight: true
                    color: Qt.rgba(0.1, 0.1, 0.1, 0.5)
                    border.color: "#00ff00"
                    border.width: 1
                    radius: 4

                    QGCLabel {
                        anchors.centerIn: parent
                        text: "↕"
                        font.pointSize: ScreenTools.largeFontPointSize
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    QGCLabel {
                        text: "GÓC HƯỚNG"
                        color: "#888888"
                        font.pointSize: ScreenTools.smallFontPointSize - 2
                        font.family: "Monospace"
                    }

                    QGCLabel {
                        text: (_root.pitchFact ? _root.pitchFact.valueString : "--") + " °"
                        color: "#00ff00"
                        font.bold: true
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.family: "Monospace"
                    }
                }
            }
        }

        // ROLL
        Rectangle {
            width: parent.width
            height: ScreenTools.defaultFontPixelHeight * 4
            color: Qt.rgba(0.05, 0.05, 0.05, 0.98)
            border.color: "#00bfff"
            border.width: 2
            radius: 6

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.5
                    Layout.fillHeight: true
                    color: Qt.rgba(0.1, 0.1, 0.1, 0.5)
                    border.color: "#00bfff"
                    border.width: 1
                    radius: 4

                    QGCLabel {
                        anchors.centerIn: parent
                        text: "↔"
                        font.pointSize: ScreenTools.largeFontPointSize
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    QGCLabel {
                        text: "GÓC LIỆNG"
                        color: "#888888"
                        font.pointSize: ScreenTools.smallFontPointSize - 2
                        font.family: "Monospace"
                    }

                    QGCLabel {
                        text: (_root.rollFact ? _root.rollFact.valueString : "--") + " °"
                        color: "#00bfff"
                        font.bold: true
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.family: "Monospace"
                    }
                }
            }
        }
    }

    VehicleWarnings {
        anchors.centerIn: parent
        z: QGroundControl.zOrderTopMost
    }

    MapScale {
        id: mapScale
        anchors.margins: _toolsMargin
        anchors.left: parent.left
        anchors.top: parent.top
        mapControl: _mapControl
        buttonsOnLeft: false
        visible: !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Loader {
        id: preFlightChecklistLoader
        sourceComponent: preFlightChecklistPopup
        active: false
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
}
