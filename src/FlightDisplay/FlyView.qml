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

    // These should only be used by MainRootWindow
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

    function _calcCenterViewPort() {
        if (widgetLayer && widgetLayer.toolStrip) {
            var newToolInset = Qt.rect(0, 0, width, height)
            widgetLayer.toolStrip.adjustToolInset(newToolInset)
        }
    }

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

            // BẮT TÍN HIỆU TỪ NÚT BẤM VÀ THAY ĐỔI TRẠNG THÁI
            onSetHomeModeToggled: {
                _root.isSettingHome = !_root.isSettingHome;
            }
        }

        FlyViewCustomLayer { id: customOverlay; anchors.fill: widgetLayer; z: _fullItemZorder + 2; parentToolInsets: widgetLayer.totalToolInsets; mapControl: _mapControl; visible: !QGroundControl.videoManager.fullScreen }
        FlyViewInsetViewer { id: widgetLayerInsetViewer; anchors.fill: parent; z: widgetLayer.z + 1; insetsToView: widgetLayer.totalToolInsets; visible: false }

        // MOUSE AREA TRONG SUỐT ĐỂ BẮT SỰ KIỆN CLICK
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

    //---------- COMPONENT CHO DIALOG XÁC NHẬN "SET HOME" ----------
    Component {
        id: setHomeConfirmationDialogComponent
        Dialog {
            property var selectedCoordinate

            // Bỏ tiêu đề và các nút bấm mặc định
            // title:           qsTr("Xác nhận Vị trí Home Mới")
            // standardButtons: Dialog.Yes | Dialog.No

            // Chúng ta sẽ tự tạo toàn bộ giao diện
            standardButtons: Dialog.NoButton

            parent: Overlay.overlay
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            // Kích thước sẽ tự động điều chỉnh
            implicitWidth:  contentColumn.implicitWidth
            implicitHeight: contentColumn.implicitHeight

            // Nền tối và bo góc
            background: Rectangle {
                color: Qt.rgba(0.2, 0.2, 0.2, 0.95) // Màu xám đậm
                border.color: Qt.rgba(1, 1, 1, 0.2)
                radius: 8
            }

            contentItem: ColumnLayout {
                id:         contentColumn
                spacing:    ScreenTools.defaultFontPixelWidth * 1.5 // Tăng khoảng cách

                // TIÊU ĐỀ MỚI
                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Xác nhận Vị trí Home Mới")
                    font.pointSize:     ScreenTools.largeFontPointSize
                    font.bold:          true
                }

                // NỘI DUNG CHÍNH
                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Bạn có chắc chắn muốn đặt Vị trí Home tại đây?")
                }

                // KHUNG CHỨA TỌA ĐỘ VỚI NỀN RIÊNG
                Rectangle {
                    Layout.fillWidth:   true
                    color:              Qt.rgba(0, 0, 0, 0.5) // Nền đen mờ
                    radius:             4

                    Column {
                        anchors.fill:       parent
                        anchors.margins:    ScreenTools.defaultFontPixelWidth

                        QGCLabel {
                            text: qsTr("Vĩ độ: %1").arg(selectedCoordinate.latitude.toFixed(7))
                        }
                        QGCLabel {
                            text: qsTr("Kinh độ: %1").arg(selectedCoordinate.longitude.toFixed(7))
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    Layout.topMargin:   ScreenTools.defaultFontPixelWidth
                    spacing:            ScreenTools.defaultFontPixelWidth // Thêm khoảng cách giữa 2 nút

                    // --- Nút Hủy ---
                    QGCButton {
                        // Để nút tự co giãn theo chiều rộng của text, không chiếm hết không gian
                        Layout.fillWidth:   true
                        text:               qsTr("Hủy")
                        onClicked:          reject()
                    }

                    // --- Nút Xác nhận ---
                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Xác nhận")
                        primary:            true
                        onClicked:          accept()

                        // Yêu cầu nút này trở thành nút mặc định (có thể được kích hoạt bằng Enter)
                        DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                    }
                }
            }

            // Logic xử lý vẫn giữ nguyên
            onAccepted: {
                if (_activeVehicle) {
                    _activeVehicle.doSetHome(selectedCoordinate);
                }
                _root.isSettingHome = false;
            }
            onRejected: {
                _root.isSettingHome = false;
            }
        }
    }
    //-----------------------------------------------------------------

    //---------- THANH THÔNG BÁO HƯỚNG DẪN "SET HOME" ----------
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
            text:                   qsTr("Đang ở chế độ Đặt Home: Nhấn vào bản đồ để chọn vị trí.")
            font.bold:              true
            color:                  "lightgreen"
        }
    }
    //-------------------------------------------------------------
}
