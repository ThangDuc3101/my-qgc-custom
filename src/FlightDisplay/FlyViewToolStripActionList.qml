/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist
    signal setHomeModeToggled // <-- TÍN HIỆU MỚI CHO NÚT ĐẶT HOME

    model: [
        ToolStripAction {
            property bool _is3DViewOpen:            viewer3DWindow.isOpen
            property bool   _viewer3DEnabled:       QGroundControl.settingsManager.viewer3DSettings.enabled.rawValue

            id: view3DIcon
            visible: _viewer3DEnabled
            text:           qsTr("3D View")
            iconSource:     "/qml/QGroundControl/Viewer3D/City3DMapIcon.svg"
            onTriggered:{
                if(_is3DViewOpen === false){
                    viewer3DWindow.open()
                }else{
                    viewer3DWindow.close()
                }
            }

            on_Is3DViewOpenChanged: {
                if(_is3DViewOpen === true){
                    view3DIcon.iconSource =     "/qmlimages/PaperPlane.svg"
                    text=           qsTr("Bay")
                }else{
                    iconSource =     "/qml/QGroundControl/Viewer3D/City3DMapIcon.svg"
                    text =           qsTr("3D View")
                }
            }
        },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },

        //---------- NÚT MỞ CÀI ĐẶT VIDEO  ----------
        ToolStripAction
        {
            text:       qsTr("Camera")
            iconSource: "qrc:/qmlimages/camera_video.svg" // Sử dụng icon tốt hơn
            visible:    true
            onTriggered:
            {
                mainWindow.showSettingsTool("Video")
            }
        },
        //---------------------------------------------------------

        //---------- NÚT MỚI ĐỂ BẬT CHẾ ĐỘ "ĐẶT VỊ TRÍ HỦY NHIỆM VỤ" ----------
        ToolStripAction {
            text:       qsTr("Đặt VTHNV")
            iconSource: "qrc:/qmlimages/Home.svg"

            // Chỉ bật khi phương tiện đã được kích hoạt (armed)
            // enabled:    QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.armed : false
            enabled:    true
            visible:    QGroundControl.multiVehicleManager.activeVehicle

            onTriggered: {
                // Khi nhấn, phát tín hiệu "setHomeModeToggled" ra ngoài
                _root.setHomeModeToggled()
            }
        },
        //-----------------------------------------------------

        FlyViewAdditionalActionsButton { },
        GuidedActionGripper { }
    ]
}
