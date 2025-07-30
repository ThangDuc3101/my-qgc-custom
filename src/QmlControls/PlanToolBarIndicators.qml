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
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls

import QGroundControl.UTMSP

// Toolbar for Plan View
Item {
    id: _root
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
    property string _gradientText:                  isNaN(_gradient) ?                  "-.-" : _gradient.toFixed(0) + " độ"
    property string _azimuthText:                   isNaN(_azimuth) ?                   "-.-" : Math.round(_azimuth) % 360
    property string _headingText:                   isNaN(_heading) ?                   "-.-" : Math.round(_heading) % 360
    property string _missionPlannedDistanceText:    isNaN(_missionPlannedDistance) ?    "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _missionMaxTelemetryText:       isNaN(_missionMaxTelemetry) ?       "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _batteryChangePointText:        _batteryChangePoint < 0 ?           "K/A" : _batteryChangePoint // K/A = Không áp dụng
    property string _batteriesRequiredText:         _batteriesRequired < 0 ?            "K/A" : _batteriesRequired

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    property bool isSerialActive: false

    property bool _utmspEnabled: QGroundControl.utmspSupported

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
            complete = days + " ngày " + Qt.formatTime(t, 'hh:mm:ss')
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
            text:        _controllerDirty ? "Cần Tải lên" : "Tải lên"
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

        QGCButton {
            id:          savePlanButton
            text:        "Lưu Kế Hoạch"
            enabled:     true
            onClicked: {
                _planMasterController.saveMissionWaypointsAsJson()
            }
        }

        QGCButton {
            id:          sendPlanButton
            text:        "Gửi Kế Hoạch"
            enabled:     true
            onClicked: {
                _planMasterController.sendSavedPlanToServer()
            }
        }

        QGCButton {
            id:          serialToggleButton
            text:        isSerialActive ? "Dừng Serial" : "Bắt đầu Serial"
            enabled:     !_controllerSyncInProgress
            primary:     isSerialActive
            property var configDialog: null
            onClicked: {
                if (isSerialActive) {
                    _planMasterController.stopSerialListener();
                } else {
                    configDialog = serialConfigDialogComponent.createObject(_root);
                    configDialog.open();
                }
            }
            Connections {
                target: serialToggleButton.configDialog
                function onClosed() {
                    if (serialToggleButton.configDialog) {
                        serialToggleButton.configDialog.destroy()
                    }
                }
            }
        }

        GridLayout {
            columns:                8
            rowSpacing:             _rowSpacing
            columnSpacing:          _labelToValueSpacing

            QGCLabel {
                text:               "Waypoint Đã chọn"
                Layout.columnSpan:  8
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel { text: "Chênh cao:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _altDifferenceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: "Góc PV:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _azimuthText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _smallValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: "Cự ly WP trước:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _distanceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }

            QGCLabel { text: "Độ dốc:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _gradientText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: "Hướng:"; font.pointSize: _dataFontSize; }
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
                text:               "Toàn bộ Kế hoạch"
                Layout.columnSpan:  5
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel { text: "Tổng cự ly:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _missionPlannedDistanceText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }

            Item { width: 1; height: 1 }

            QGCLabel { text: "Cự ly Telem tối đa:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _missionMaxTelemetryText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _largeValueWidth
            }

            QGCLabel { text: "Thời gian:"; font.pointSize: _dataFontSize; }
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
                text:               "Pin"
                Layout.columnSpan:  3
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCLabel { text: "Số pin yêu cầu:"; font.pointSize: _dataFontSize; }
            QGCLabel {
                text:                   _batteriesRequiredText
                font.pointSize:         _dataFontSize
                Layout.minimumWidth:    _mediumValueWidth
            }
        }
    }

    Component {
        id: serialConfigDialogComponent

        Dialog {
            id:             dialog
            title:          "Cấu hình Cổng Serial"
            standardButtons: Dialog.Ok | Dialog.Cancel
            modal:          true
            width:          ScreenTools.defaultFontPixelWidth * 30

            property alias selectedPort:   portComboBox.currentValue
            property alias selectedBaud:   baudComboBox.currentValue

            ColumnLayout {
                anchors.fill: parent

                Label { text: "Cổng Serial:" }
                ComboBox {
                    id:             portComboBox
                    Layout.fillWidth: true
                    Component.onCompleted: {
                        if (_planMasterController) {
                            model = _planMasterController.getAvailableSerialPorts()
                        }
                    }
                }

                Label { text: "Tốc độ Baud:" }
                ComboBox {
                    id:             baudComboBox
                    Layout.fillWidth: true
                    model: [ 9600, 19200, 38400, 57600, 115200 ]
                    currentIndex: 4
                }
            }

            onAccepted: {
                var success = _planMasterController.startSerialListener(selectedPort, selectedBaud);
                if (success) {
                    _root.isSerialActive = true;
                } else {
                    qgcApp.showAppMessage("Không thể kết nối đến cổng serial. Vui lòng kiểm tra console.");
                }
            }

            onRejected: {
                 _root.isSerialActive = false;
            }
        }
    }
}
