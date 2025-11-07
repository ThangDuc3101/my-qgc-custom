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

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: _root

    property Item pipView
    property Item pipState: videoPipState

    property int    _track_rec_x:       0
    property int    _track_rec_y:       0

    // Properties cho video stabilization
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property real   _rollAngle:         _activeVehicle ? _activeVehicle.roll.rawValue : 0
    property bool   _stabilizeVideo:    true
    property real   _pitchAngle:        _activeVehicle ? _activeVehicle.pitch.rawValue : 0
    property bool   _showHorizon:       true
    property real _stabilizationStrength: 0.3

    PipState {
        id:         videoPipState
        pipView:    _root.pipView
        isDark:     true

        onWindowAboutToOpen: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onWindowAboutToClose: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onStateChanged: {
            if (pipState.state !== pipState.fullState) {
                QGroundControl.videoManager.fullScreen = false
            }
        }
    }

    Timer {
        id:           videoStartDelay
        interval:     2000;
        running:      false
        repeat:       false
        onTriggered:  QGroundControl.videoManager.startVideo()
    }

    //-- Video Streaming với Rotation
    Item {
        id: videoContainer
        anchors.fill: parent
        visible: QGroundControl.videoManager.isStreamSource
        clip: true

        // Scale factor để video không bị cắt góc khi xoay
        property real scaleFactor: {
            if (!_stabilizeVideo) return 1.0
            var angleRad = Math.abs(_rollAngle) * Math.PI / 180
            var cos = Math.cos(angleRad)
            var sin = Math.sin(angleRad)
            var scaleX = 1 / (cos + sin * (height/width))
            var scaleY = 1 / (cos + sin * (width/height))
            return Math.max(scaleX, scaleY, 1.0)
        }

        FlightDisplayViewVideo {
            id:             videoStreaming
            anchors.centerIn: parent
            width:          parent.width * videoContainer.scaleFactor
            height:         parent.height * videoContainer.scaleFactor
            useSmallFont:   _root.pipState.state !== _root.pipState.fullState

            // Thêm rotation transform
            transform: Rotation {
                origin.x: videoStreaming.width / 2
                origin.y: videoStreaming.height / 2
                angle: _stabilizeVideo ? -_rollAngle * _stabilizationStrength : 0

                Behavior on angle {
                    NumberAnimation {
                        duration: 50
                        easing.type: Easing.Linear
                    }
                }
            }
        }

        // Horizon overlay
        Item {
            anchors.fill: parent
            visible: _showHorizon && _stabilizeVideo

            // Horizon line
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.7
                height: 2
                color: "red"
                opacity: 0.5

                transform: Rotation {
                    origin.x: width / 2
                    origin.y: height / 2
                    angle: _rollAngle
                }
            }

            // Center crosshair
            Item {
                anchors.centerIn: parent
                Rectangle {
                    anchors.centerIn: parent
                    width: 30
                    height: 1
                    color: "#ffff00"
                    opacity: 0.8
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 30
                    color: "#ffff00"
                    opacity: 0.8
                }
            }
        }
    }

    //-- UVC Video (USB Camera or Video Device)
    Loader {
        id:             cameraLoader
        anchors.fill:   parent
        visible:        QGroundControl.videoManager.isUvc
        source:         QGroundControl.videoManager.uvcEnabled ? "qrc:/qml/QGroundControl/FlightDisplay/FlightDisplayViewUVC.qml" : "qrc:/qml/QGroundControl/FlightDisplay//FlightDisplayViewDummy.qml"
    }

    QGCLabel {
        text: qsTr("Double-click to exit full screen")
        font.pointSize: ScreenTools.largeFontPointSize
        visible: QGroundControl.videoManager.fullScreen && flyViewVideoMouseArea.containsMouse
        anchors.centerIn: parent

        onVisibleChanged: {
            if (visible) {
                labelAnimation.start()
            }
        }

        PropertyAnimation on opacity {
            id: labelAnimation
            duration: 10000
            from: 1.0
            to: 0.0
            easing.type: Easing.InExpo
        }
    }

    // ============= MILITARY HUD OVERLAY (RESPONSIVE WITH SLIDING INDICATORS) =============
    Item {
        id: militaryHud
        anchors.fill: parent
        visible: _activeVehicle !== null
        z: 900

        // Detect if in PiP mode (small size)
        property bool isPipMode: pipState.state === pipState.pipState
        property real scaleFactor: isPipMode ? 0.55 : 1.0

        // ===== THANH ROLL PHÍA TRÊN (LOWER POSITION) =====
        Item {
            id: topRollScale
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 120
            width: parent.width * 0.15 * militaryHud.scaleFactor
            height: 24 * militaryHud.scaleFactor
            visible: true

            // Background bar
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.25)
                border.color: "#ff0000"
                border.width: 1.5 * militaryHud.scaleFactor
            }

            // Scale marks
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 5 * militaryHud.scaleFactor
                spacing: parent.width / 6

                Repeater {
                    model: 7
                    Rectangle {
                        width: 1 * militaryHud.scaleFactor
                        height: (index % 3 === 0 ? 10 : 5) * militaryHud.scaleFactor
                        color: "#ff0000"
                    }
                }
            }

            // Center roll value
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -5 * militaryHud.scaleFactor
                width: (rollText.width + 10) * militaryHud.scaleFactor
                height: (rollText.height + 3) * militaryHud.scaleFactor
                color: Qt.rgba(0, 0, 0, 0.9)
                border.color: "#ff0000"
                border.width: 1.5 * militaryHud.scaleFactor

                QGCLabel {
                    id: rollText
                    anchors.centerIn: parent
                    text: _activeVehicle ? Math.round(_rollAngle) + "°" : "0°"
                    color: "#ff0000"
                    font.bold: true
                    font.pointSize: (ScreenTools.mediumFontPointSize - 1) * militaryHud.scaleFactor
                    font.family: "Monospace"
                }
            }

            // Label
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 2 * militaryHud.scaleFactor
                text: "ROLL"
                color: "#ff0000"
                font.pointSize: (ScreenTools.mediumFontPointSize - 3) * militaryHud.scaleFactor
                font.family: "Monospace"
            }
        }

        // ===== THANH DỌC TRÁI - TỐC ĐỘ (SLIDING INDICATOR) =====
        Item {
            id: leftSpeedScale
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: parent.width * (militaryHud.isPipMode ? 0.08 : 0.12)
            width: 50 * militaryHud.scaleFactor
            height: parent.height * 0.3 * militaryHud.scaleFactor

            // Background
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.25)
                border.color: "#ff0000"
                border.width: 1.5 * militaryHud.scaleFactor
            }

            // Scale marks
            Column {
                anchors.fill: parent
                anchors.margins: 2 * militaryHud.scaleFactor
                spacing: (parent.height - 4 * militaryHud.scaleFactor) / 6

                Repeater {
                    model: militaryHud.isPipMode ? 5 : 7
                    Row {
                        width: parent.width
                        spacing: 2 * militaryHud.scaleFactor

                        Rectangle {
                            width: (index % 3 === 0 ? 8 : 4) * militaryHud.scaleFactor
                            height: 1 * militaryHud.scaleFactor
                            color: "#ff0000"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCLabel {
                            text: militaryHud.isPipMode ?
                                  Math.round((4 - index) * 30) :
                                  Math.round((6 - index) * 20)
                            color: "#ff0000"
                            font.pointSize: (ScreenTools.mediumFontPointSize - 5) * militaryHud.scaleFactor
                            font.family: "Monospace"
                            visible: index % 3 === 0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Current speed indicator (SLIDING)
            Item {
                anchors.right: parent.right
                anchors.rightMargin: -5 * militaryHud.scaleFactor
                // ← DYNAMIC Y POSITION based on speed
                y: {
                    if (!_activeVehicle) return parent.height / 2
                    var currentSpeed = _activeVehicle.groundSpeed.rawValue * 3.6  // km/h
                    var maxSpeed = 120  // Max scale
                    var percentage = Math.max(0, Math.min(1, currentSpeed / maxSpeed))
                    return parent.height * (1 - percentage) - height / 2
                }
                width: 48 * militaryHud.scaleFactor
                height: 20 * militaryHud.scaleFactor

                Behavior on y {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.9)
                    border.color: "#ff0000"
                    border.width: 1.5 * militaryHud.scaleFactor

                    QGCLabel {
                        anchors.centerIn: parent
                        text: _activeVehicle ? Math.round(_activeVehicle.groundSpeed.rawValue * 3.6) : "0"
                        color: "#ff0000"
                        font.bold: true
                        font.pointSize: (ScreenTools.mediumFontPointSize - 1) * militaryHud.scaleFactor
                        font.family: "Monospace"
                    }
                }

                // Triangle pointer
                Canvas {
                    anchors.right: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6 * militaryHud.scaleFactor
                    height: 8 * militaryHud.scaleFactor

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = "#ff0000";
                        ctx.beginPath();
                        ctx.moveTo(width, height/2);
                        ctx.lineTo(0, 0);
                        ctx.lineTo(0, height);
                        ctx.closePath();
                        ctx.fill();
                    }

                    // Repaint when parent moves
                    Connections {
                        target: parent
                        function onYChanged() { requestPaint() }
                    }
                }
            }

            // Label
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 2 * militaryHud.scaleFactor
                text: "km/h"
                color: "#ff0000"
                font.pointSize: (ScreenTools.mediumFontPointSize - 3) * militaryHud.scaleFactor
                font.family: "Monospace"
                visible: !militaryHud.isPipMode
            }
        }

        // ===== THANH DỌC PHẢI - ĐỘ CAO (SLIDING INDICATOR) =====
        Item {
            id: rightAltitudeScale
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: parent.width * (militaryHud.isPipMode ? 0.08 : 0.12)
            width: 58 * militaryHud.scaleFactor
            height: parent.height * 0.3 * militaryHud.scaleFactor

            // Background
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.25)
                border.color: "#ff0000"
                border.width: 1.5 * militaryHud.scaleFactor
            }

            // Scale marks
            Column {
                anchors.fill: parent
                anchors.margins: 2 * militaryHud.scaleFactor
                spacing: (parent.height - 4 * militaryHud.scaleFactor) / 6

                Repeater {
                    model: militaryHud.isPipMode ? 5 : 7
                    Row {
                        width: parent.width
                        spacing: 2 * militaryHud.scaleFactor
                        layoutDirection: Qt.RightToLeft

                        Rectangle {
                            width: (index % 3 === 0 ? 8 : 4) * militaryHud.scaleFactor
                            height: 1 * militaryHud.scaleFactor
                            color: "#ff0000"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCLabel {
                            text: militaryHud.isPipMode ?
                                  Math.round((4 - index) * 150) + "m" :
                                  Math.round((6 - index) * 100) + "m"
                            color: "#ff0000"
                            font.pointSize: (ScreenTools.mediumFontPointSize - 5) * militaryHud.scaleFactor
                            font.family: "Monospace"
                            visible: index % 3 === 0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Current altitude indicator (SLIDING)
            Item {
                anchors.left: parent.left
                anchors.leftMargin: -5 * militaryHud.scaleFactor
                // ← DYNAMIC Y POSITION based on altitude
                y: {
                    if (!_activeVehicle || !_activeVehicle.altitudeAMSL) return parent.height / 2
                    var currentAlt = _activeVehicle.altitudeAMSL.rawValue
                    var maxAlt = 600  // Max scale
                    var percentage = Math.max(0, Math.min(1, currentAlt / maxAlt))
                    return parent.height * (1 - percentage) - height / 2
                }
                width: 52 * militaryHud.scaleFactor
                height: 20 * militaryHud.scaleFactor

                Behavior on y {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.9)
                    border.color: "#ff0000"
                    border.width: 1.5 * militaryHud.scaleFactor

                    QGCLabel {
                        anchors.centerIn: parent
                        text: _activeVehicle && _activeVehicle.altitudeAMSL ?
                              Math.round(_activeVehicle.altitudeAMSL.rawValue) + "m" : "0m"
                        color: "#ff0000"
                        font.bold: true
                        font.pointSize: (ScreenTools.mediumFontPointSize - 1) * militaryHud.scaleFactor
                        font.family: "Monospace"
                    }
                }

                // Triangle pointer
                Canvas {
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6 * militaryHud.scaleFactor
                    height: 8 * militaryHud.scaleFactor

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = "#ff0000";
                        ctx.beginPath();
                        ctx.moveTo(0, height/2);
                        ctx.lineTo(width, 0);
                        ctx.lineTo(width, height);
                        ctx.closePath();
                        ctx.fill();
                    }

                    // Repaint when parent moves
                    Connections {
                        target: parent
                        function onYChanged() { requestPaint() }
                    }
                }
            }

            // Label
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 2 * militaryHud.scaleFactor
                text: "AMSL"
                color: "#ff0000"
                font.pointSize: (ScreenTools.mediumFontPointSize - 3) * militaryHud.scaleFactor
                font.family: "Monospace"
                visible: !militaryHud.isPipMode
            }
        }

        // ===== CROSSHAIR (RESPONSIVE) =====
        Item {
            anchors.centerIn: parent
            width: 60 * militaryHud.scaleFactor
            height: 60 * militaryHud.scaleFactor

            Rectangle {
                anchors.centerIn: parent
                width: 25 * militaryHud.scaleFactor
                height: 2 * militaryHud.scaleFactor
                color: "#ff0000"
            }

            Rectangle {
                anchors.centerIn: parent
                width: 2 * militaryHud.scaleFactor
                height: 25 * militaryHud.scaleFactor
                color: "#ff0000"
            }

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -12 * militaryHud.scaleFactor
                width: 16 * militaryHud.scaleFactor
                height: 2 * militaryHud.scaleFactor
                color: "#0088ff"
            }

            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -12 * militaryHud.scaleFactor
                width: 2 * militaryHud.scaleFactor
                height: 4 * militaryHud.scaleFactor
                color: "#0088ff"
            }

            Rectangle {
                anchors.centerIn: parent
                width: 35 * militaryHud.scaleFactor
                height: 35 * militaryHud.scaleFactor
                radius: 17.5 * militaryHud.scaleFactor
                color: "transparent"
                border.color: "#ff0000"
                border.width: 1.5 * militaryHud.scaleFactor
            }

            Rectangle {
                anchors.centerIn: parent
                width: 4 * militaryHud.scaleFactor
                height: 4 * militaryHud.scaleFactor
                radius: 2 * militaryHud.scaleFactor
                color: "#ff0000"
            }
        }

        // ===== CORNER BRACKETS (RESPONSIVE) =====
        Repeater {
            model: 4
            Canvas {
                x: index < 2 ? 35 : parent.width - 60 * militaryHud.scaleFactor
                y: (index % 2 === 0) ? 35 : parent.height - 60 * militaryHud.scaleFactor
                width: 25 * militaryHud.scaleFactor
                height: 25 * militaryHud.scaleFactor
                visible: !militaryHud.isPipMode

                property bool isLeft: index < 2
                property bool isTop: index % 2 === 0

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#ff0000";
                    ctx.lineWidth = 2 * militaryHud.scaleFactor;

                    ctx.beginPath();
                    if (isLeft) {
                        ctx.moveTo(width, isTop ? 0 : height);
                        ctx.lineTo(0, isTop ? 0 : height);
                        ctx.lineTo(0, isTop ? height : 0);
                    } else {
                        ctx.moveTo(0, isTop ? 0 : height);
                        ctx.lineTo(width, isTop ? 0 : height);
                        ctx.lineTo(width, isTop ? height : 0);
                    }
                    ctx.stroke();
                }
            }
        }
    }
    // ============= END MILITARY HUD =============

    OnScreenGimbalController {
        id:                      onScreenGimbalController
        anchors.fill:            parent
        screenX:                 flyViewVideoMouseArea.mouseX
        screenY:                 flyViewVideoMouseArea.mouseY
        cameraTrackingEnabled:   videoStreaming._camera && videoStreaming._camera.trackingEnabled
    }

    MouseArea {
        id:                         flyViewVideoMouseArea
        anchors.fill:               parent
        enabled:                    pipState.state === pipState.fullState
        hoverEnabled:               true

        property double x0:         0
        property double x1:         0
        property double y0:         0
        property double y1:         0
        property double offset_x:   0
        property double offset_y:   0
        property double radius:     20
        property var trackingROI:   null
        property var trackingStatus: trackingStatusComponent.createObject(flyViewVideoMouseArea, {})

        function convertMouseCoords(mouseX, mouseY) {
            if (!_stabilizeVideo) {
                return Qt.point(mouseX, mouseY)
            }

            var centerX = videoStreaming.width / 2
            var centerY = videoStreaming.height / 2
            var relX = mouseX - centerX
            var relY = mouseY - centerY

            var angleRad = _rollAngle * Math.PI / 180
            var cos = Math.cos(angleRad)
            var sin = Math.sin(angleRad)

            var rotX = relX * cos - relY * sin
            var rotY = relX * sin + relY * cos

            return Qt.point(rotX + centerX, rotY + centerY)
        }

        onClicked:       onScreenGimbalController.clickControl()
        onDoubleClicked: QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen

        onPressed:(mouse) => {
            onScreenGimbalController.pressControl()

            var coords = convertMouseCoords(mouse.x, mouse.y)
            _track_rec_x = coords.x
            _track_rec_y = coords.y

            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    trackingROI = trackingROIComponent.createObject(flyViewVideoMouseArea, {
                        "x": mouse.x,
                        "y": mouse.y
                    });
                }
            }
        }

        onPositionChanged: (mouse) => {
            if (trackingROI !== null) {
                if (mouse.x < trackingROI.x) {
                    trackingROI.x = mouse.x
                    trackingROI.width = Math.abs(mouse.x - _track_rec_x)
                } else {
                    trackingROI.width = Math.abs(mouse.x - trackingROI.x)
                }
                if (mouse.y < trackingROI.y) {
                    trackingROI.y = mouse.y
                    trackingROI.height = Math.abs(mouse.y - _track_rec_y)
                } else {
                    trackingROI.height = Math.abs(mouse.y - trackingROI.y)
                }
            }
        }

        onReleased: (mouse) => {
            onScreenGimbalController.releaseControl()

            if (trackingROI !== null) {
                trackingROI.destroy();
            }

            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    var coords = convertMouseCoords(mouse.x, mouse.y)

                    x0 = Math.min(_track_rec_x, coords.x)
                    x1 = Math.max(_track_rec_x, coords.x)
                    y0 = Math.min(_track_rec_y, coords.y)
                    y1 = Math.max(_track_rec_y, coords.y)

                    offset_x = (parent.width - videoStreaming.getWidth()) / 2
                    offset_y = (parent.height - videoStreaming.getHeight()) / 2

                    x0 = x0 - offset_x
                    x1 = x1 - offset_x
                    y0 = y0 - offset_y
                    y1 = y1 - offset_y

                    x0 = Math.max(Math.min(x0 / videoStreaming.getWidth(), 1.0), 0.0)
                    x1 = Math.max(Math.min(x1 / videoStreaming.getWidth(), 1.0), 0.0)
                    y0 = Math.max(Math.min(y0 / videoStreaming.getHeight(), 1.0), 0.0)
                    y1 = Math.max(Math.min(y1 / videoStreaming.getHeight(), 1.0), 0.0)

                    if (Math.abs(_track_rec_x - coords.x) < 10 && Math.abs(_track_rec_y - coords.y) < 10) {
                        var pt  = Qt.point(x0, y0)
                        videoStreaming._camera.startTracking(pt, radius / videoStreaming.getWidth())
                    } else {
                        var rec = Qt.rect(x0, y0, x1 - x0, y1 - y0)
                        videoStreaming._camera.startTracking(rec)
                    }
                    _track_rec_x = 0
                    _track_rec_y = 0
                }
            }
        }

        Component {
            id: trackingROIComponent

            Rectangle {
                color:              Qt.rgba(0.1,0.85,0.1,0.25)
                border.color:       "green"
                border.width:       1
            }
        }

        Component {
            id: trackingStatusComponent

            Rectangle {
                color:              "transparent"
                border.color:       "red"
                border.width:       5
                radius:             5
            }
        }

        Timer {
            id: trackingStatusTimer
            interval:               50
            repeat:                 true
            running:                true
            onTriggered: {
                if (videoStreaming._camera) {
                    if (videoStreaming._camera.trackingEnabled && videoStreaming._camera.trackingImageStatus) {
                        var margin_hor = (parent.parent.width - videoStreaming.getWidth()) / 2
                        var margin_ver = (parent.parent.height - videoStreaming.getHeight()) / 2
                        var left = margin_hor + videoStreaming.getWidth() * videoStreaming._camera.trackingImageRect.left
                        var top = margin_ver + videoStreaming.getHeight() * videoStreaming._camera.trackingImageRect.top
                        var right = margin_hor + videoStreaming.getWidth() * videoStreaming._camera.trackingImageRect.right
                        var bottom = margin_ver + !isNaN(videoStreaming._camera.trackingImageRect.bottom) ? videoStreaming.getHeight() * videoStreaming._camera.trackingImageRect.bottom : top + (right - left)
                        var width = right - left
                        var height = bottom - top

                        flyViewVideoMouseArea.trackingStatus.x = left
                        flyViewVideoMouseArea.trackingStatus.y = top
                        flyViewVideoMouseArea.trackingStatus.width = width
                        flyViewVideoMouseArea.trackingStatus.height = height
                    } else {
                        flyViewVideoMouseArea.trackingStatus.x = 0
                        flyViewVideoMouseArea.trackingStatus.y = 0
                        flyViewVideoMouseArea.trackingStatus.width = 0
                        flyViewVideoMouseArea.trackingStatus.height = 0
                    }
                }
            }
        }
    }

    ProximityRadarVideoView{
        anchors.fill:   parent
        vehicle:        QGroundControl.multiVehicleManager.activeVehicle
    }

    ObstacleDistanceOverlayVideo {
        id: obstacleDistance
        showText: pipState.state === pipState.fullState
    }

    // Control Panel for Video Stabilization
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 180
        height: 100
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 5
        visible: pipState.state === pipState.fullState

        Column {
            anchors.centerIn: parent
            spacing: 5

            Row {
                spacing: 8
                QGCLabel {
                    text: "Stabilize:"
                    color: "white"
                    font.pointSize: ScreenTools.smallFontPointSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                QGCSwitch {
                    checked: _stabilizeVideo
                    onClicked: _stabilizeVideo = !_stabilizeVideo
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: 8
                QGCLabel {
                    text: "Horizon:"
                    color: "white"
                    font.pointSize: ScreenTools.smallFontPointSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                QGCSwitch {
                    checked: _showHorizon
                    onClicked: _showHorizon = !_showHorizon
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            QGCLabel {
                text: "Roll: " + _rollAngle.toFixed(1) + "°"
                color: "#00ff00"
                font.family: "Monospace"
                font.pointSize: ScreenTools.smallFontPointSize
            }

            QGCLabel {
                text: "Pitch: " + _pitchAngle.toFixed(1) + "°"
                color: "#00ff00"
                font.family: "Monospace"
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }
    }
}
