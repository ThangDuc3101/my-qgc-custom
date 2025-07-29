import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls

import QGroundControl.UTMSP

// Toolbar for Plan View
Item {
    width: missionStats.width + _margins

    property var    planMasterController

    property var    _planMasterController:      planMasterController
    property var    _currentMissionItem:        _planMasterController.missionController.currentPlanViewItem ///< Mission item to display status for

    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real   missionPlannedDistance:     _controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0
    property real   missionMaxTelemetry:        _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
    property bool   missionDirty:               _controllerValid ? _planMasterController.missionController.dirty : false

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property bool   _controllerOffline:         _controllerValid ? _planMasterController.offline : true
    property var    _controllerDirty:           _controllerValid ? _planMasterController.dirty : false
    property var    _controllerSyncInProgress:  _controllerValid ? _planMasterController.syncInProgress : false

    property bool   _currentMissionItemValid:   _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
    property bool   _curreItemIsFlyThrough:     _currentMissionItemValid && _currentMissionItem.specifiesCoordinate && !_currentMissionItem.isStandaloneCoordinate
    property bool   _currentItemIsVTOLTakeoff:  _currentMissionItemValid && _currentMissionItem.command == 84
    property bool   _missionValid:              missionItems !== undefined

    property real   _dataFontSize:              ScreenTools.defaultFontPointSize
    property real   _largeValueWidth:           ScreenTools.defaultFontPixelWidth * 8
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 4
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 3
    property real   _labelToValueSpacing:       ScreenTools.defaultFontPixelWidth
    property real   _rowSpacing:                ScreenTools.isMobile ? 1 : 0
    property real   _distance:                  _currentMissionItemValid ? _currentMissionItem.distance : NaN
    property real   _altDifference:             _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
    property real   _azimuth:                   _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
    property real   _heading:                   _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
    property real   _missionPlannedDistance:    _missionValid ? missionPlannedDistance : NaN
    property real   _missionMaxTelemetry:       _missionValid ? missionMaxTelemetry : NaN
    property real   _missionTime:               _missionValid ? missionTime : 0
    property int    _batteryChangePoint:        _controllerValid ? _planMasterController.missionController.batteryChangePoint : -1
    property int    _batteriesRequired:         _controllerValid ? _planMasterController.missionController.batteriesRequired : -1
    property bool   _batteryInfoAvailable:      _batteryChangePoint >= 0 || _batteriesRequired >= 0
    property real   _gradient:                  _currentMissionItemValid && _currentMissionItem.distance > 0 ?
                                                    (_currentItemIsVTOLTakeoff ?
                                                         0 :
                                                         (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0/Math.PI)))
                                                  : NaN

    property string _distanceText:                  isNaN(_distance) ?                  "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _altDifferenceText:             isNaN(_altDifference) ?             "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altDifference).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _gradientText:                  isNaN(_gradient) ?                  "-.-" : _gradient.toFixed(0) + qsTr(" deg")
    property string _azimuthText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_azimuth) % 360
    property string _headingText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_heading) % 360
    property string _missionPlannedDistanceText:    isNaN(_missionPlannedDistance) ?    "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _missionMaxTelemetryText:       isNaN(_missionMaxTelemetry) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _batteryChangePointText:        _batteryChangePoint < 0 ?           qsTr("N/A") : _batteryChangePoint
    property string _batteriesRequiredText:         _batteriesRequired < 0 ?            qsTr("N/A") : _batteriesRequired

    readonly property real _margins: ScreenTools.defaultFontPixelWidth


    //-------------- PROPERTIES FOR SERIAL ---------------
    property bool   isSerialActive:     false
    //----------------------------------------------------

    // Properties of UTM adapter
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days == 31) {
            days = '0'
            complete = Qt.formatTime(t, 'hh:mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'hh:mm:ss')
        }
        return complete
    }

    RowLayout {
        id:                     missionStats
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.leftMargin:     _margins
        anchors.left:           parent.left
        spacing:                ScreenTools.defaultFontPixelWidth * 2

        QGCButton {
            id:          uploadButton
            text:        _controllerDirty ? qsTr("Upload Required") : qsTr("Upload")
            enabled:     _utmspEnabled ? !_controllerSyncInProgress && UTMSPStateStorage.enableMissionUploadButton : !_controllerSyncInProgress
            visible:     !_controllerOffline && !_controllerSyncInProgress
            primary:     _controllerDirty
            onClicked: {
                if (_utmspEnabled) {
                    QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
                    UTMSPStateStorage.removeFlightPlanState = true
                    UTMSPStateStorage.indicatorDisplayStatus = true
                }
                _planMasterController.upload();
            }

            PropertyAnimation on opacity {
                easing.type:    Easing.OutQuart
                from:           0.5
                to:             1
                loops:          Animation.Infinite
                running:        _controllerDirty && !_controllerSyncInProgress
                alwaysRunToEnd: true
                duration:       2000
            }
        }
        //---------- THÊM NÚT SAVE, NÚT SEND, NÚT SERIAL ----------

        QGCButton
        {
            id:          savePlanButton
            text:        qsTr("Save Plan")
            // Tạm thời để enabled, sau này có thể thêm logic
            enabled:     true

            onClicked:
            {
                console.log("Save Plan button clicked!")
                _planMasterController.saveMissionWaypointsAsJson()
            }
        }

        QGCButton
        {
            id:          sendPlanButton
            text:        qsTr("Send Plan")

            enabled:     true

            onClicked:
            {
                console.log("Send Plan button clicked!")
                _planMasterController.sendSavedPlanToServer()
            }
        }

        QGCButton {
            id:          serialToggleButton
            text:        isSerialActive ? qsTr("Stop Serial") : qsTr("Start Serial")
            enabled:     !_controllerSyncInProgress
            primary:     isSerialActive

            // Biến để lưu trữ dialog đang mở
            property var configDialog: null

            onClicked: {
                if (isSerialActive)
                {
                    _planMasterController.stopSerialListener();
                    isSerialActive = false;
                }
                else
                {
                    configDialog = serialConfigDialogComponent.createObject(this);
                    configDialog.open();
                }
            }

            // Tự động dọn dẹp dialog sau khi nó bị đóng lại
            Connections {
                target: serialToggleButton.configDialog
                function onClosed() {
                    if (serialToggleButton.configDialog) {
                        serialToggleButton.configDialog.destroy()
                    }
                }
            }
        }

        //----------------------------------------------

        GridLayout {
            columns:                8
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            QGCLabel {
                text:               qsTr("Selected Waypoint")
                Layout.columnSpan:  8
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel { text: qsTr("Alt diff:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _altDifferenceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: qsTr("Azimuth:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _azimuthText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _smallValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: qsTr("Dist prev WP:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _distanceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }

            QGCLabel { text: qsTr("Gradient:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _gradientText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: qsTr("Heading:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _headingText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _smallValueWidth
            }
        }

        GridLayout {
            columns:                5
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            QGCLabel {
                text:               qsTr("Total Mission")
                Layout.columnSpan:  5
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel { text: qsTr("Distance:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _missionPlannedDistanceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: qsTr("Max telem dist:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _missionMaxTelemetryText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }

            QGCLabel { text: qsTr("Time:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   getMissionTime()
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }
        }

        GridLayout {
            columns:                3
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing
            visible:                _batteryInfoAvailable

            QGCLabel {
                text:               qsTr("Battery")
                Layout.columnSpan:  3
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel { text: qsTr("Batteries required:"); font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _batteriesRequiredText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
            }
        }
    }
    //------------ KHỐI MÃ DIALOG -------------
        Component {
            id: serialConfigDialogComponent

            Dialog {
                id:             dialog
                title:          qsTr("Serial Port Configuration")
                standardButtons: Dialog.Ok | Dialog.Cancel
                modal:          true
                width:          ScreenTools.defaultFontPixelWidth * 30

                property alias selectedPort:   portComboBox.currentValue
                property alias selectedBaud:   baudComboBox.currentValue

                ColumnLayout {
                    anchors.fill: parent

                    Label { text: qsTr("Serial Port:") }
                    ComboBox {
                        id:             portComboBox
                        Layout.fillWidth: true

                        // model: [ "/dev/ttyUSB0", "/dev/ttyUSB1", "/dev/ttyACM0" ] // Tạm thời để test giao diện
                        Component.onCompleted:
                        {
                            if (_planMasterController)
                            {
                                model = _planMasterController.getAvailableSerialPorts()
                            }
                        }
                    }

                    Label { text: qsTr("Baud Rate:") }
                    ComboBox {
                        id:             baudComboBox
                        Layout.fillWidth: true
                        model: [ 9600, 19200, 38400, 57600, 115200 ]
                        currentIndex: 4 // Mặc định là 115200
                    }
                }

                onAccepted:
                {
                    console.log("Dialog accepted. Attempting to connect to Port:", selectedPort, "at Baud:", selectedBaud);
                    var success = _planMasterController.startSerialListener(selectedPort, selectedBaud);
                    if (success) {
                        isSerialActive = true;
                    } else {
                        // Có thể thêm thông báo lỗi ở đây nếu muốn
                        console.log("Failed to connect to serial port.");
                    }
                }
            }
        }
}

