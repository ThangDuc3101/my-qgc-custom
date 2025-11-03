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
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : (horizontalToolStrip.visible ? ScreenTools.defaultFontPixelHeight * 5 : parentToolInsets.bottomEdgeLeftInset)
        bottomEdgeCenterInset:  horizontalToolStrip.visible ? ScreenTools.defaultFontPixelHeight * 5 : 0
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

    // HORIZONTAL TOOLSTRIP
    Row {
        id:                     horizontalToolStrip
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   _toolsMargin * 2
        spacing:                _margins * 2
        z:                      QGroundControl.zOrderWidgets
        visible:                !QGroundControl.videoManager.fullScreen

        // Không override height, để QML tự tính

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
            buttonText: qsTr("CAMERA")
            buttonIcon: "📷"
            visible: _activeVehicle
            onClicked: {
                // Open Application Settings > Video page
                mainWindow.showSettingsDialog()
                // Note: Cần thêm logic để tự động chọn Video tab
                // Có thể cần modify SettingsDialog để nhận parameter
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

    //---------- VIDEO FEED (TOP LEFT) ----------
    Rectangle {
        id:                 videoFeedContainer
        anchors.left:       parent.left
        anchors.top:        parent.top
        anchors.margins:    _layoutMargin
        width:              ScreenTools.defaultFontPixelWidth * 45  // Tăng lên 45 để rộng đến "Hold"
        height:             width * 0.56  // 16:9 aspect ratio (thay vì 4:3)
        color:              Qt.rgba(0, 0, 0, 0.9)
        border.color:       "#00bfff"
        border.width:       3
        radius:             8
        z:                  QGroundControl.zOrderWidgets
        visible:            QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen

        // Glow effect
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

        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            color: "transparent"
            border.color: "#00bfff"
            border.width: 1
            radius: parent.radius + 4
            opacity: 0.1
            z: -2
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

            // Blinking effect
            SequentialAnimation on opacity {
                running: QGroundControl.videoManager.videoRunning
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.3; duration: 500 }
                NumberAnimation { from: 0.3; to: 1.0; duration: 500 }
            }
        }
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       parent.left
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      false
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

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
