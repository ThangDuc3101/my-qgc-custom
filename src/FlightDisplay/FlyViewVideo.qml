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
                // angle: _stabilizeVideo ? -_rollAngle : 0
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

        // Helper function để convert mouse coords khi video bị xoay
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

            //create a new rectangle at the wanted position
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
            //on move, update the width of rectangle
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

            //if there is already a selection, delete it
            if (trackingROI !== null) {
                trackingROI.destroy();
            }

            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    var coords = convertMouseCoords(mouse.x, mouse.y)

                    // order coordinates --> top/left and bottom/right
                    x0 = Math.min(_track_rec_x, coords.x)
                    x1 = Math.max(_track_rec_x, coords.x)
                    y0 = Math.min(_track_rec_y, coords.y)
                    y1 = Math.max(_track_rec_y, coords.y)

                    //calculate offset between video stream rect and background (black stripes)
                    offset_x = (parent.width - videoStreaming.getWidth()) / 2
                    offset_y = (parent.height - videoStreaming.getHeight()) / 2

                    //convert absolute coords in background to absolute video stream coords
                    x0 = x0 - offset_x
                    x1 = x1 - offset_x
                    y0 = y0 - offset_y
                    y1 = y1 - offset_y

                    //convert absolute to relative coordinates and limit range to 0...1
                    x0 = Math.max(Math.min(x0 / videoStreaming.getWidth(), 1.0), 0.0)
                    x1 = Math.max(Math.min(x1 / videoStreaming.getWidth(), 1.0), 0.0)
                    y0 = Math.max(Math.min(y0 / videoStreaming.getHeight(), 1.0), 0.0)
                    y1 = Math.max(Math.min(y1 / videoStreaming.getHeight(), 1.0), 0.0)

                    //use point message if rectangle is very small
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

            // Toggle stabilization
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

            // Toggle horizon
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

            // Show roll angle
            QGCLabel {
                text: "Roll: " + _rollAngle.toFixed(1) + "°"
                color: "#00ff00"
                font.family: "Monospace"
                font.pointSize: ScreenTools.smallFontPointSize
            }

            // Show pitch angle
            QGCLabel {
                text: "Pitch: " + _pitchAngle.toFixed(1) + "°"
                color: "#00ff00"
                font.family: "Monospace"
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }
    }
}
