/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools

import QGroundControl.Controls
import QGroundControl.FlightMap

/// GeoFence map visuals
Item {
    id: _root
    z: QGroundControl.zOrderMapItems

    property var    map
    property var    myGeoFenceController
    property bool   interactive:            false
    property bool   planView:               false
    property var    homePosition

    property var    _breachReturnPointComponent
    property var    _breachReturnDragComponent
    property var    _paramCircleFenceComponent
    // QUAN TRỌNG: Thuộc tính _polygons này nhận dữ liệu tự động từ C++.
    // - Trong Plan View, nó nhận hàng rào GỐC.
    // - Trong Fly View, nó nhận hàng rào AN TOÀN.
    property var    _polygons:                  myGeoFenceController.polygons
    property var    _circles:                   myGeoFenceController.circles
    property color  _borderColor:               "orange"
    property int    _borderWidthInclusion:      2
    property int    _borderWidthExclusion:      0
    property color  _interiorColorExclusion:    "orange"
    property color  _interiorColorInclusion:    "transparent"
    property real   _interiorOpacityExclusion:  0.2 * opacity
    property real   _interiorOpacityInclusion:  1 * opacity

    // Hàm này chỉ tính toán và gửi dữ liệu an toàn về C++. Nó không vẽ gì cả.
    function processAndBuildSafePolygon(polygon) {
        if (!polygon || !polygon.path || polygon.path.length < 3) {
            myGeoFenceController.updateSafePolygonPath([]);
            return;
        }

        var oldPath = polygon.path;
        var totalLat = 0.0, totalLon = 0.0;
        for (var i = 0; i < oldPath.length; i++) {
            totalLat += oldPath[i].latitude;
            totalLon += oldPath[i].longitude;
        }
        var centroid = QtPositioning.coordinate(totalLat / oldPath.length, totalLon / oldPath.length);
        var newCoords = [];
        var shrinkDistanceMeters = 200.0;

        for (var j = 0; j < oldPath.length; j++) {
            var vertex = oldPath[j];
            var distanceToCentroid = centroid.distanceTo(vertex);
            var azimuth = centroid.azimuthTo(vertex);
            var newDistance = distanceToCentroid - shrinkDistanceMeters;

            if (newDistance > 0) {
                newCoords.push(centroid.atDistanceAndAzimuth(newDistance, azimuth));
            } else {
                newCoords.push(vertex);
            }
        }

        myGeoFenceController.updateSafePolygonPath(newCoords);
    }

    // >>> BẮT ĐẦU KHỐI LOGIC HIỂN THỊ DUY NHẤT <<<
    // Instantiator này sẽ vẽ duy nhất MỘT hàng rào.
    // Dữ liệu và màu sắc của nó sẽ thay đổi tùy theo chế độ xem.
    Instantiator {
        model: _polygons
        delegate : QGCMapPolygonVisuals {
            parent: _root
            mapControl: map
            mapPolygon: object // Dữ liệu được cung cấp tự động bởi _polygons
            borderWidth: object.inclusion ? _borderWidthInclusion : _borderWidthExclusion

            // >>> THAY ĐỔI CỐT LÕI: Màu sắc động <<<
            // - Nếu ở Plan View, màu sẽ là "đỏ" (chế độ chỉnh sửa).
            // - Nếu ở Fly View, màu sẽ là cam tiêu chuẩn.
            borderColor: _root.planView ? "red" : _borderColor

            interactive: _root.interactive && object && object.interactive

            // Chỉ kết nối tín hiệu này khi ở Plan View để tính toán
            Connections {
                target: object
                // Bỏ qua nếu không ở Plan View
                enabled: _root.planView

                onPathChanged: {
                    // Khi người dùng kéo thả, tính lại hàng rào an toàn
                    _root.processAndBuildSafePolygon(object);
                }
            }
            Component.onCompleted: {
                if (_root.planView) {
                    // Khi tạo mới, tính hàng rào an toàn lần đầu
                    Qt.callLater(function() {
                        _root.processAndBuildSafePolygon(object);
                    })
                }
            }
        }
    }

    // Theo dõi việc thêm/xóa đa giác để tính toán lại
    Connections {
        target: _polygons
        enabled: _root.planView // Chỉ cần thiết trong Plan View
        onCountChanged: {
            var lastPolygon = _polygons.count > 0 ? _polygons.get(_polygons.count - 1) : null;
            processAndBuildSafePolygon(lastPolygon);
        }
    }
    // >>> KẾT THÚC KHỐI LOGIC HIỂN THỊ DUY NHẤT <<<

    function addPolygon(inclusionPolygon) {
        var rect = Qt.rect(map.centerViewport.x, map.centerViewport.y, map.centerViewport.width, map.centerViewport.height);
        rect.x += (rect.width * 0.25) / 2;
        rect.y += (rect.height * 0.25) / 2;
        rect.width *= 0.75;
        rect.height *= 0.75;
        var centerCoord = map.toCoordinate(Qt.point(rect.x + (rect.width / 2), rect.y + (rect.height / 2)), false);
        var topLeftCoord = map.toCoordinate(Qt.point(rect.x, rect.y), false);
        var topRightCoord = map.toCoordinate(Qt.point(rect.x + rect.width, rect.y), false);
        var bottomLeftCoord = map.toCoordinate(Qt.point(rect.x, rect.y + rect.height), false);
        var bottomRightCoord = map.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false);
        var halfWidthMeters = Math.min(topLeftCoord.distanceTo(topRightCoord), 3000) / 2;
        var halfHeightMeters = Math.min(topLeftCoord.distanceTo(bottomLeftCoord), 3000) / 2;
        topLeftCoord = centerCoord.atDistanceAndAzimuth(halfWidthMeters, -90).atDistanceAndAzimuth(halfHeightMeters, 0);
        topRightCoord = centerCoord.atDistanceAndAzimuth(halfWidthMeters, 90).atDistanceAndAzimuth(halfHeightMeters, 0);
        bottomLeftCoord = centerCoord.atDistanceAndAzimuth(halfWidthMeters, -90).atDistanceAndAzimuth(halfHeightMeters, 180);
        bottomRightCoord = centerCoord.atDistanceAndAzimuth(halfWidthMeters, 90).atDistanceAndAzimuth(halfHeightMeters, 180);
        if (inclusionPolygon) {
            myGeoFenceController.addInclusionPolygon(topLeftCoord, bottomRightCoord);
        }
    }

    Component.onCompleted: {
        _breachReturnPointComponent = breachReturnPointComponent.createObject(map);
        map.addMapItem(_breachReturnPointComponent);
        _breachReturnDragComponent = breachReturnDragComponent.createObject(map, { "itemIndicator": _breachReturnPointComponent });
        _paramCircleFenceComponent = paramCircleFenceComponent.createObject(map);
        map.addMapItem(_paramCircleFenceComponent);
    }

    Component.onDestruction: {
        if (_breachReturnPointComponent) _breachReturnPointComponent.destroy();
        if (_breachReturnDragComponent) _breachReturnDragComponent.destroy();
        if (_paramCircleFenceComponent) _paramCircleFenceComponent.destroy();
    }

    // (Các thành phần còn lại không thay đổi)
    Instantiator { model: _circles; delegate : QGCMapCircleVisuals { parent: _root; mapControl: map; mapCircle: object; borderWidth: object.inclusion ? _borderWidthInclusion : _borderWidthExclusion; borderColor: _borderColor; interiorColor: object.inclusion ? _interiorColorInclusion : _interiorColorExclusion; interiorOpacity: object.inclusion ? _interiorOpacityInclusion : _interiorOpacityExclusion; interactive: _root.interactive && mapCircle && mapCircle.interactive } }
    Component { id: paramCircleFenceComponent; MapCircle { color: _interiorColorInclusion; opacity: _interiorOpacityInclusion; border.color: _borderColor; border.width: _borderWidthInclusion; center: homePosition; radius: _radius; visible: homePosition.isValid && _radius > 0; property real _radius: myGeoFenceController ? myGeoFenceController.paramCircularFence : 0 } }
    Component { id: breachReturnDragComponent; MissionItemIndicatorDrag { mapControl: map; itemCoordinate: myGeoFenceController ? myGeoFenceController.breachReturnPoint : undefined; visible: _root.interactive; onItemCoordinateChanged: { if(myGeoFenceController) { myGeoFenceController.breachReturnPoint = itemCoordinate } } } }
    Component { id: breachReturnPointComponent; MapQuickItem { anchorPoint.x: sourceItem.anchorPointX; anchorPoint.y: sourceItem.anchorPointY; z: QGroundControl.zOrderMapItems; coordinate: myGeoFenceController ? myGeoFenceController.breachReturnPoint : undefined; opacity: _root.opacity; sourceItem: MissionItemIndexLabel { label: qsTr("B", "Breach Return Point item indicator"); checked: true } } }
}
