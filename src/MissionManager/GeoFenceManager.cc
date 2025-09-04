/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "GeoFenceManager.h"
#include "Vehicle.h"
#include "QmlObjectListModel.h"
#include "QGCLoggingCategory.h"

QGC_LOGGING_CATEGORY(GeoFenceManagerLog, "GeoFenceManagerLog")

GeoFenceManager::GeoFenceManager(Vehicle* vehicle)
    : PlanManager       (vehicle, MAV_MISSION_TYPE_FENCE)
{
    connect(this, &PlanManager::inProgressChanged,          this, &GeoFenceManager::inProgressChanged);
    connect(this, &PlanManager::error,                      this, &GeoFenceManager::error);
    connect(this, &PlanManager::removeAllComplete,          this, &GeoFenceManager::removeAllComplete);
    connect(this, &PlanManager::sendComplete,               this, &GeoFenceManager::_sendComplete);
    connect(this, &PlanManager::newMissionItemsAvailable,   this, &GeoFenceManager::_planManagerLoadComplete);
}

GeoFenceManager::~GeoFenceManager()
{

}

void GeoFenceManager::sendToVehicle(const QGeoCoordinate&   breachReturn,
                                    QmlObjectListModel&     polygons,
                                    QmlObjectListModel&     circles)
{
    qCDebug(GeoFenceManagerLog) << "sendToVehicle: Intercepting data before sending to vehicle.";

            // >>> BẮT ĐẦU LOGIC CAN THIỆP <<<
    QList<QGCFencePolygon> safePolygons;
    const double shrinkFactor = 0.8;

    for (int i = 0; i < polygons.count(); i++) {
        QGCFencePolygon* userPolygon = qobject_cast<QGCFencePolygon*>(polygons.get(i));
        if (!userPolygon || userPolygon->count() < 3) continue;

        double totalLat = 0.0, totalLon = 0.0;
        int vertexCount = userPolygon->count();
        for (int j = 0; j < vertexCount; j++) {
            QGeoCoordinate c = userPolygon->path()[j].value<QGeoCoordinate>();
            totalLat += c.latitude();
            totalLon += c.longitude();
        }
        QGeoCoordinate centroid(totalLat / vertexCount, totalLon / vertexCount);
        QGCFencePolygon newSafePolygon(userPolygon->inclusion());
        for (int j = 0; j < vertexCount; j++) {
            QGeoCoordinate originalVertex = userPolygon->path()[j].value<QGeoCoordinate>();
            double vecLat = originalVertex.latitude() - centroid.latitude();
            double vecLon = originalVertex.longitude() - centroid.longitude();
            double newLat = centroid.latitude() + vecLat * shrinkFactor;
            double newLon = centroid.longitude() + vecLon * shrinkFactor;
            newSafePolygon.appendVertex(QGeoCoordinate(newLat, newLon));
        }
        safePolygons.append(newSafePolygon);
    }
    // >>> KẾT THÚC LOGIC CAN THIỆP <<<

    QList<MissionItem*> fenceItems;
    _sendPolygons.clear();
    _sendCircles.clear();

    for (int i=0; i<polygons.count(); i++) {
        _sendPolygons.append(*polygons.value<QGCFencePolygon*>(i));
    }
    for (int i=0; i<circles.count(); i++) {
        _sendCircles.append(*circles.value<QGCFenceCircle*>(i));
    }
    _breachReturnPoint = breachReturn;

    for (const QGCFencePolygon& polygon : safePolygons) {
        for (int j=0; j<polygon.count(); j++) {
            const QGeoCoordinate& vertex = polygon.path()[j].value<QGeoCoordinate>();
            MissionItem* item = new MissionItem(0,
                                                polygon.inclusion() ? MAV_CMD_NAV_FENCE_POLYGON_VERTEX_INCLUSION : MAV_CMD_NAV_FENCE_POLYGON_VERTEX_EXCLUSION,
                                                MAV_FRAME_GLOBAL,
                                                polygon.count(),
                                                0, 0, 0,
                                                vertex.latitude(),
                                                vertex.longitude(),
                                                0,
                                                false, false, this);
            fenceItems.append(item);
        }
    }

    for (int i=0; i<_sendCircles.count(); i++) {
        QGCFenceCircle& circle = _sendCircles[i];
        MissionItem* item = new MissionItem(0,
                                            circle.inclusion() ? MAV_CMD_NAV_FENCE_CIRCLE_INCLUSION : MAV_CMD_NAV_FENCE_CIRCLE_EXCLUSION,
                                            MAV_FRAME_GLOBAL,
                                            circle.radius()->rawValue().toDouble(),
                                            0, 0, 0,
                                            circle.center().latitude(),
                                            circle.center().longitude(),
                                            0,
                                            false, false, this);
        fenceItems.append(item);
    }
    if (_breachReturnPoint.isValid()) {
        MissionItem* item = new MissionItem(0,
                                            MAV_CMD_NAV_FENCE_RETURN_POINT,
                                            MAV_FRAME_GLOBAL_RELATIVE_ALT,
                                            0, 0, 0, 0,
                                            breachReturn.latitude(),
                                            breachReturn.longitude(),
                                            breachReturn.altitude(),
                                            false, false, this);
        fenceItems.append(item);
    }
    writeMissionItems(fenceItems);
}

void GeoFenceManager::removeAll(void)
{
    _polygons.clear();
    _circles.clear();
    _breachReturnPoint = QGeoCoordinate();
    PlanManager::removeAll();
}

void GeoFenceManager::_sendComplete(bool error)
{
    if (error) {
        _polygons.clear();
        _circles.clear();
        _breachReturnPoint = QGeoCoordinate();
    } else {
        _polygons = _sendPolygons;
        _circles = _sendCircles;
    }
    _sendPolygons.clear();
    _sendCircles.clear();
    emit sendComplete(error);
}

void GeoFenceManager::_planManagerLoadComplete(bool removeAllRequested)
{
    bool loadFailed = false;
    Q_UNUSED(removeAllRequested);
    _polygons.clear();
    _circles.clear();
    MAV_CMD expectedCommand = (MAV_CMD)0;
    int expectedVertexCount = 0;
    QGCFencePolygon nextPolygon(true /* inclusion */);
    const QList<MissionItem*>& fenceItems = missionItems();
    for (int i=0; i<fenceItems.count(); i++) {
        MissionItem* item = fenceItems[i];
        MAV_CMD command = item->command();
        if (command == MAV_CMD_NAV_FENCE_POLYGON_VERTEX_INCLUSION || command == MAV_CMD_NAV_FENCE_POLYGON_VERTEX_EXCLUSION) {
            if (nextPolygon.count() == 0) {
                expectedVertexCount = item->param1();
                expectedCommand = command;
            } else if (expectedVertexCount != item->param1()){
                emit error(BadPolygonItemFormat, tr("GeoFence load: Vertex count change mid-polygon - actual:expected") + QString(" %1:%2").arg(item->param1()).arg(expectedVertexCount));
                break;
            } else if (expectedCommand != command) {
                emit error(BadPolygonItemFormat, tr("GeoFence load: Polygon type changed before last load complete - actual:expected") + QString(" %1:%2").arg(command).arg(expectedCommand));
                break;
            }
            nextPolygon.appendVertex(QGeoCoordinate(item->param5(), item->param6()));
            if (nextPolygon.count() == expectedVertexCount) {
                nextPolygon.setInclusion(command == MAV_CMD_NAV_FENCE_POLYGON_VERTEX_INCLUSION);
                _polygons.append(nextPolygon);
                nextPolygon.clear();
            }
        } else if (command == MAV_CMD_NAV_FENCE_CIRCLE_INCLUSION || command == MAV_CMD_NAV_FENCE_CIRCLE_EXCLUSION) {
            if (nextPolygon.count() != 0) {
                emit error(IncompletePolygonLoad, tr("GeoFence load: Incomplete polygon loaded"));
                break;
            }
            QGCFenceCircle circle(QGeoCoordinate(item->param5(), item->param6()), item->param1(), command == MAV_CMD_NAV_FENCE_CIRCLE_INCLUSION /* inclusion */);
            _circles.append(circle);
        } else if (command == MAV_CMD_NAV_FENCE_RETURN_POINT) {
            _breachReturnPoint = QGeoCoordinate(item->param5(), item->param6(), item->param7());
        } else {
            emit error(UnsupportedCommand, tr("GeoFence load: Unsupported command %1").arg(item->command()));
            break;
        }
    }
    if (loadFailed) {
        _polygons.clear();
        _circles.clear();
        _breachReturnPoint = QGeoCoordinate();
    }
    emit loadComplete();
}

bool GeoFenceManager::supported(void) const
{
    return (_vehicle->capabilityBits() & MAV_PROTOCOL_CAPABILITY_MISSION_FENCE) && (_vehicle->maxProtoVersion() >= 200);
}
