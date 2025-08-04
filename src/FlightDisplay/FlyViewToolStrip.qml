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

ToolStrip {
    id: _root

    signal displayPreFlightChecklist

    // BƯỚC 1: Thêm một tín hiệu mới để "chuyền" đi
    signal setHomeModeToggled

    FlyViewToolStripActionList {
        id: flyViewToolStripActionList

        onDisplayPreFlightChecklist: _root.displayPreFlightChecklist()

        // BƯỚC 2: Khi nhận được tín hiệu từ con, hãy phát tín hiệu của chính mình
        onSetHomeModeToggled: _root.setHomeModeToggled()
    }

    model: flyViewToolStripActionList.model
}
