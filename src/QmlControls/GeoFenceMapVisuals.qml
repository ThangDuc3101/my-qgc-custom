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
    property var    _polygons:                  myGeoFenceController.polygons
    property var    _circles:                   myGeoFenceController.circles
    property color  _borderColor:               "orange"
    property int    _borderWidthInclusion:      2
    property int    _borderWidthExclusion:      0
    property color  _interiorColorExclusion:    "orange"
    property color  _interiorColorInclusion:    "transparent"
    property real   _interiorOpacityExclusion:  0.2 * opacity
    property real   _interiorOpacityInclusion:  1 * opacity
    property var    safePolygonPath: []
    QtObject { id: safePolygonDataObject; property var path: _root.safePolygonPath }

    function processAndBuildSafePolygon(polygon) {
        if (!polygon || !polygon.path || polygon.path.length < 3) {
            safePolygonPath = [];
            if(myGeoFenceController) { myGeoFenceController.updateSafePolygonPath(safePolygonPath); }
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
        var shrinkFactor = 0.8;
        for (var j = 0; j < oldPath.length; j++) {
            var originalVertex = oldPath[j];
            var vecLat = originalVertex.latitude - centroid.latitude;
            var vecLon = originalVertex.longitude - centroid.longitude;
            var newLat = centroid.latitude + vecLat * shrinkFactor;
            var newLon = centroid.longitude + vecLon * shrinkFactor;
            newCoords.push(QtPositioning.coordinate(newLat, newLon));
        }
        safePolygonPath = newCoords;
        if (myGeoFenceController) {
            myGeoFenceController.updateSafePolygonPath(safePolygonPath);
        }
    }

    // >>> BẮT ĐẦU SỬA LỖI <<<
    Connections {
        target: _polygons
        onCountChanged: {
            var lastPolygon = _polygons.count > 0 ? _polygons.get(_polygons.count - 1) : null;
            processAndBuildSafePolygon(lastPolygon);
        }
    }
    // >>> KẾT THÚC SỬA LỖI <<<

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
            myGeoFenceController.addInclusion(topLeftCoord, bottomRightCoord);
        } else {
            myGeoFenceController.addExclusion(topLeftCoord, bottomRightCoord);
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

    Instantiator {
        model: _polygons
        delegate : QGCMapPolygonVisuals {
            parent: _root
            mapControl: map
            mapPolygon: object
            borderWidth: object.inclusion ? _borderWidthInclusion : _borderWidthExclusion
            borderColor: _borderColor
            interiorColor: object.inclusion ? _interiorColorInclusion : _interiorColorExclusion
            interiorOpacity: object.inclusion ? _interiorOpacityInclusion : _interiorOpacityExclusion
            interactive: _root.interactive && object && object.interactive
            Connections {
                target: object
                onPathChanged: {
                    _root.processAndBuildSafePolygon(object);
                }
            }
            Component.onCompleted: {
                Qt.callLater(function() {
                    _root.processAndBuildSafePolygon(object);
                })
            }
        }
    }

    QGCMapPolygonVisuals {
        mapControl: map
        mapPolygon: safePolygonDataObject
        borderColor: "red"
        borderWidth: 2
        interactive: false
        visible: safePolygonPath.length > 0
    }

    Instantiator {
        model: _circles
        delegate : QGCMapCircleVisuals {
            parent:             _root
            mapControl:         map
            mapCircle:          object
            borderWidth:        object.inclusion ? _borderWidthInclusion : _borderWidthExclusion
            borderColor:        _borderColor
            interiorColor:      object.inclusion ? _interiorColorInclusion : _interiorColorExclusion
            interiorOpacity:    object.inclusion ? _interiorOpacityInclusion : _interiorOpacityExclusion
            interactive:         _root.interactive && mapCircle && mapCircle.interactive
        }
    }

    Component {
        id: paramCircleFenceComponent
        MapCircle {
            color:          _interiorColorInclusion
            opacity:        _interiorOpacityInclusion
            border.color:   _borderColor
            border.width:   _borderWidthInclusion
            center:         homePosition
            radius:         _radius
            visible:        homePosition.isValid && _radius > 0
            property real _radius: myGeoFenceController ? myGeoFenceController.paramCircularFence : 0
        }
    }

    Component {
        id: breachReturnDragComponent
        MissionItemIndicatorDrag {
            mapControl:     map
            itemCoordinate: myGeoFenceController ? myGeoFenceController.breachReturnPoint : undefined
            visible:        _root.interactive
            onItemCoordinateChanged: {
                if(myGeoFenceController) {
                    myGeoFenceController.breachReturnPoint = itemCoordinate
                }
            }
        }
    }

    Component {
        id: breachReturnPointComponent
        MapQuickItem {
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            z:              QGroundControl.zOrderMapItems
            coordinate:     myGeoFenceController ? myGeoFenceController.breachReturnPoint : undefined
            opacity:        _root.opacity
            sourceItem: MissionItemIndexLabel {
                label:      qsTr("B", "Breach Return Point item indicator")
                checked:    true
            }
        }
    }
}
