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

    //---------- BIẾN TRẠNG THÁI CHO WORKFLOW "SET HOME" ----------
    property bool isSettingHome: false
    //-------------------------------------------------------------

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
        PipView { id: _pipView; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: _toolsMargin; item1IsFullSettingsKey: "MainFlyWindowIsMap"; item1: mapControl; item2: QGroundControl.videoManager.hasVideo ? videoControl : null; show: QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen && (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState); z: QGroundControl.zOrderWidgets; property real leftEdgeBottomInset: visible ? width + anchors.margins : 0; property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0 }

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

    //---------- COMPONENT CHO DIALOG XÁC NHẬN "SET HOME" (ĐÃ SỬA BỐ CỤC) ----------
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
                color: Qt.rgba(0.2, 0.2, 0.2, 0.95)
                border.color: Qt.rgba(1, 1, 1, 0.2)
                radius: 8
            }

            contentItem: ColumnLayout {
                id:         contentColumn
                width: parent.width

                spacing:    ScreenTools.defaultFontPixelWidth

                // --- TIÊU ĐỀ ---
                QGCLabel {
                    Layout.fillWidth:       true
                    horizontalAlignment:    Text.AlignHCenter
                    text:                   qsTr("XÁC NHẬN")
                    font.pointSize:         ScreenTools.largeFontPointSize
                    font.bold:              true
                    bottomPadding:          ScreenTools.defaultFontPixelWidth
                }

                // --- NỘI DUNG ---
                QGCLabel {
                    Layout.fillWidth:       true
                    horizontalAlignment:    Text.AlignHCenter
                    text:                   qsTr("Bạn có chắc chắn muốn đặt Vị trí hủy nhiệm vụ ở đây?")
                    wrapMode:               Text.WordWrap
                }

                // --- KHUNG TỌA ĐỘ ---
                Rectangle {
                    Layout.fillWidth:   true
                    implicitHeight:     coordLayout.implicitHeight + (anchors.margins * 2)
                    color:              Qt.rgba(0, 0, 0, 0.5)
                    radius:             4

                    GridLayout {
                        id:             coordLayout
                        anchors.fill:   parent
                        anchors.margins: ScreenTools.defaultFontPixelWidth / 2
                        columns:        2
                        columnSpacing:  ScreenTools.defaultFontPixelWidth

                        QGCLabel { text: qsTr("Vĩ độ:") }
                        QGCLabel {
                            text: selectedCoordinate.latitude.toFixed(7)
                            font.bold: true
                            Layout.alignment: Qt.AlignRight
                        }

                        QGCLabel { text: qsTr("Kinh độ:") }
                        QGCLabel {
                            text: selectedCoordinate.longitude.toFixed(7)
                            font.bold: true
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                DialogButtonBox
                {
                    Layout.fillWidth:   true
                    Layout.topMargin:   ScreenTools.defaultFontPixelWidth

                    // THÊM KHỐI NÀY ĐỂ LÀM CHO NỀN TRONG SUỐT
                    background: Item {}

                    QGCButton {
                        text:               qsTr("Hủy")
                        onClicked:          reject()
                        DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                    }
                    QGCButton {
                        text:               qsTr("Xác nhận")
                        primary:            true
                        onClicked:          accept()
                        DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
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
    //-----------------------------------------------------------------

    //---------- THANH THÔNG BÁO HƯỚNG DẪN ----------
    Rectangle {
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.top:                toolbar.bottom
        anchors.topMargin:          _margins

        width:                      instructionLabel.implicitWidth + (_margins * 4)
        height:                     instructionLabel.implicitHeight + (_margins * 2)

        color:                      Qt.rgba(0, 0, 0, 0.7)
        radius:                     5

        visible:                    isSettingHome
        z:                          QGroundControl.zOrderWidgets

        QGCLabel {
            id:                     instructionLabel
            anchors.centerIn:       parent
            text:                   qsTr("Đang ở chế độ Đặt Vị trí hủy nhiệm vu: Nhấn vào bản đồ để chọn vị trí.")
            font.bold:              true
            color:                  "lightgreen"
        }
    }
    //-------------------------------------------------------------
}
