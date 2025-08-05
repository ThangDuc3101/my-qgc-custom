/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "PlanMasterController.h"
#include "QGCApplication.h"
#include "QGCCorePlugin.h"
#include "MultiVehicleManager.h"
#include "Vehicle.h"
#include "SettingsManager.h"
#include "AppSettings.h"
#include "JsonHelper.h"
#include "MissionManager.h"
#include "KMLPlanDomDocument.h"
#include "SurveyPlanCreator.h"
#include "StructureScanPlanCreator.h"
#include "CorridorScanPlanCreator.h"
#include "BlankPlanCreator.h"
#include "QmlObjectListModel.h"
#include "GeoFenceManager.h"
#include "RallyPointManager.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QJsonDocument>
#include <QtCore/QFileInfo>


//---------- BỔ SUNG THƯ VIỆN CHO NÚT SAVE ----------
#include <QtWidgets/QFileDialog>
#include <QtCore/QFile>
#include <QtCore/QTextStream>
#include "MissionItem.h"
#include "VisualMissionItem.h"
#include "MissionManager/SimpleMissionItem.h"
//----------------------------------------------------

//---------- BỔ SUNG THƯ VIỆN CHO NÚT SEND ----------
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkReply>
#include <QtCore/QUrl>
//----------------------------------------------------

QGC_LOGGING_CATEGORY(PlanMasterControllerLog, "PlanMasterControllerLog")

PlanMasterController::PlanMasterController(QObject* parent)
    : QObject               (parent)
    , _multiVehicleMgr      (MultiVehicleManager::instance())
    , _controllerVehicle    (new Vehicle(Vehicle::MAV_AUTOPILOT_TRACK, Vehicle::MAV_TYPE_TRACK, this))
    , _managerVehicle       (_controllerVehicle)
    , _missionController    (this)
    , _geoFenceController   (this)
    , _rallyPointController (this)
{
    _commonInit();
}

#ifdef QT_DEBUG
PlanMasterController::PlanMasterController(MAV_AUTOPILOT firmwareType, MAV_TYPE vehicleType, QObject* parent)
    : QObject               (parent)
    , _multiVehicleMgr      (MultiVehicleManager::instance())
    , _controllerVehicle    (new Vehicle(firmwareType, vehicleType))
    , _managerVehicle       (_controllerVehicle)
    , _missionController    (this)
    , _geoFenceController   (this)
    , _rallyPointController (this)
{
    _commonInit();
}
#endif

void PlanMasterController::_commonInit(void)
{
    _previousOverallDirty = dirty();
    connect(&_missionController,    &MissionController::dirtyChanged,               this, &PlanMasterController::_updateOverallDirty);
    connect(&_geoFenceController,   &GeoFenceController::dirtyChanged,              this, &PlanMasterController::_updateOverallDirty);
    connect(&_rallyPointController, &RallyPointController::dirtyChanged,            this, &PlanMasterController::_updateOverallDirty);

    connect(&_missionController,    &MissionController::containsItemsChanged,       this, &PlanMasterController::containsItemsChanged);
    connect(&_geoFenceController,   &GeoFenceController::containsItemsChanged,      this, &PlanMasterController::containsItemsChanged);
    connect(&_rallyPointController, &RallyPointController::containsItemsChanged,    this, &PlanMasterController::containsItemsChanged);

    connect(&_missionController,    &MissionController::syncInProgressChanged,      this, &PlanMasterController::syncInProgressChanged);
    connect(&_geoFenceController,   &GeoFenceController::syncInProgressChanged,     this, &PlanMasterController::syncInProgressChanged);
    connect(&_rallyPointController, &RallyPointController::syncInProgressChanged,   this, &PlanMasterController::syncInProgressChanged);

    // Offline vehicle can change firmware/vehicle type
    connect(_controllerVehicle,     &Vehicle::vehicleTypeChanged,                   this, &PlanMasterController::_updatePlanCreatorsList);

    //---------- THÊM KHỞI TẠO CHO SERIAL ----------
    _serialPort = new QSerialPort(this);
    _networkManager = new QNetworkAccessManager(this);
    //-----------------------------------------------
}


PlanMasterController::~PlanMasterController()
{

}

void PlanMasterController::start(void)
{
    _missionController.start    (_flyView);
    _geoFenceController.start   (_flyView);
    _rallyPointController.start (_flyView);

    _activeVehicleChanged(_multiVehicleMgr->activeVehicle());
    connect(_multiVehicleMgr, &MultiVehicleManager::activeVehicleChanged, this, &PlanMasterController::_activeVehicleChanged);

    _updatePlanCreatorsList();
}

void PlanMasterController::startStaticActiveVehicle(Vehicle* vehicle, bool deleteWhenSendCompleted)
{
    _flyView = true;
    _deleteWhenSendCompleted = deleteWhenSendCompleted;
    _missionController.start(_flyView);
    _geoFenceController.start(_flyView);
    _rallyPointController.start(_flyView);
    _activeVehicleChanged(vehicle);
}

void PlanMasterController::_activeVehicleChanged(Vehicle* activeVehicle)
{
    if (_managerVehicle == activeVehicle) {
        // We are already setup for this vehicle
        return;
    }

    qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged" << activeVehicle;

    if (_managerVehicle) {
        // Disconnect old vehicle. Be careful of wildcarding disconnect too much since _managerVehicle may equal _controllerVehicle
        disconnect(_managerVehicle->missionManager(),       nullptr, this, nullptr);
        disconnect(_managerVehicle->geoFenceManager(),      nullptr, this, nullptr);
        disconnect(_managerVehicle->rallyPointManager(),    nullptr, this, nullptr);
    }

    bool newOffline = false;
    if (activeVehicle == nullptr) {
        // Since there is no longer an active vehicle we use the offline controller vehicle as the manager vehicle
        _managerVehicle = _controllerVehicle;
        newOffline = true;
    } else {
        newOffline = false;
        _managerVehicle = activeVehicle;

        // Update controllerVehicle to the currently connected vehicle
        AppSettings* appSettings = SettingsManager::instance()->appSettings();
        appSettings->offlineEditingFirmwareClass()->setRawValue(QGCMAVLink::firmwareClass(_managerVehicle->firmwareType()));
        appSettings->offlineEditingVehicleClass()->setRawValue(QGCMAVLink::vehicleClass(_managerVehicle->vehicleType()));

        // We use these signals to sequence upload and download to the multiple controller/managers
        connect(_managerVehicle->missionManager(),      &MissionManager::newMissionItemsAvailable,  this, &PlanMasterController::_loadMissionComplete);
        connect(_managerVehicle->geoFenceManager(),     &GeoFenceManager::loadComplete,             this, &PlanMasterController::_loadGeoFenceComplete);
        connect(_managerVehicle->rallyPointManager(),   &RallyPointManager::loadComplete,           this, &PlanMasterController::_loadRallyPointsComplete);
        connect(_managerVehicle->missionManager(),      &MissionManager::sendComplete,              this, &PlanMasterController::_sendMissionComplete);
        connect(_managerVehicle->geoFenceManager(),     &GeoFenceManager::sendComplete,             this, &PlanMasterController::_sendGeoFenceComplete);
        connect(_managerVehicle->rallyPointManager(),   &RallyPointManager::sendComplete,           this, &PlanMasterController::_sendRallyPointsComplete);
    }

    _offline = newOffline;
    emit offlineChanged(offline());
    emit managerVehicleChanged(_managerVehicle);

    if (_flyView) {
        // We are in the Fly View
        if (newOffline) {
            // No active vehicle, clear mission
            qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Fly View - No active vehicle, clearing stale plan";
            removeAll();
        } else {
            // Fly view has changed to a new active vehicle, update to show correct mission
            qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Fly View - New active vehicle, loading new plan from manager vehicle";
            _showPlanFromManagerVehicle();
        }
    } else {
        // We are in the Plan view.
        if (containsItems()) {
            // The plan view has a stale plan in it
            if (dirty()) {
                // Plan is dirty, the user must decide what to do in all cases
                qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Plan View - Previous dirty plan exists, no new active vehicle, sending promptForPlanUsageOnVehicleChange signal";
                emit promptForPlanUsageOnVehicleChange();
            } else {
                // Plan is not dirty
                if (newOffline) {
                    // The active vehicle went away with no new active vehicle
                    qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Plan View - Previous clean plan exists, no new active vehicle, clear stale plan";
                    removeAll();
                } else {
                    // We are transitioning from one active vehicle to another. Show the plan from the new vehicle.
                    qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Plan View - Previous clean plan exists, new active vehicle, loading from new manager vehicle";
                    _showPlanFromManagerVehicle();
                }
            }
        } else {
            // There is no previous Plan in the view
            if (newOffline) {
                // Nothing special to do in this case
                qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Plan View - No previous plan, no longer connected to vehicle, nothing to do";
            } else {
                // Just show the plan from the new vehicle
                qCDebug(PlanMasterControllerLog) << "_activeVehicleChanged: Plan View - No previous plan, new active vehicle, loading from new manager vehicle";
                _showPlanFromManagerVehicle();
            }
        }
    }

    // Vehicle changed so we need to signal everything
    emit containsItemsChanged(containsItems());
    emit syncInProgressChanged();
    emit dirtyChanged(dirty());

    _updatePlanCreatorsList();
}

void PlanMasterController::loadFromVehicle(void)
{
    SharedLinkInterfacePtr sharedLink = _managerVehicle->vehicleLinkManager()->primaryLink().lock();
    if (sharedLink) {
        if (sharedLink->linkConfiguration()->isHighLatency()) {
            qgcApp()->showAppMessage(tr("Download not supported on high latency links."));
            return;
        }
    } else {
        // Vehicle is shutting down
        return;
    }

    if (offline()) {
        qCWarning(PlanMasterControllerLog) << "PlanMasterController::loadFromVehicle called while offline";
    } else if (_flyView) {
        qCWarning(PlanMasterControllerLog) << "PlanMasterController::loadFromVehicle called from Fly view";
    } else if (syncInProgress()) {
        qCWarning(PlanMasterControllerLog) << "PlanMasterController::loadFromVehicle called while syncInProgress";
    } else {
        _loadGeoFence = true;
        qCDebug(PlanMasterControllerLog) << "PlanMasterController::loadFromVehicle calling _missionController.loadFromVehicle";
        _missionController.loadFromVehicle();
        setDirty(false);
    }
}


void PlanMasterController::_loadMissionComplete(void)
{
    if (!_flyView && _loadGeoFence) {
        _loadGeoFence = false;
        _loadRallyPoints = true;
        if (_geoFenceController.supported()) {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::_loadMissionComplete calling _geoFenceController.loadFromVehicle";
            _geoFenceController.loadFromVehicle();
        } else {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::_loadMissionComplete GeoFence not supported skipping";
            _geoFenceController.removeAll();
            _loadGeoFenceComplete();
        }
        setDirty(false);
    }
}

void PlanMasterController::_loadGeoFenceComplete(void)
{
    if (!_flyView && _loadRallyPoints) {
        _loadRallyPoints = false;
        if (_rallyPointController.supported()) {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::_loadGeoFenceComplete calling _rallyPointController.loadFromVehicle";
            _rallyPointController.loadFromVehicle();
        } else {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::_loadMissionComplete Rally Points not supported skipping";
            _rallyPointController.removeAll();
            _loadRallyPointsComplete();
        }
        setDirty(false);
    }
}

void PlanMasterController::_loadRallyPointsComplete(void)
{
    qCDebug(PlanMasterControllerLog) << "PlanMasterController::_loadRallyPointsComplete";
}

void PlanMasterController::_sendMissionComplete(void)
{
    if (_sendGeoFence) {
        _sendGeoFence = false;
        _sendRallyPoints = true;
        if (_geoFenceController.supported()) {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle start GeoFence sendToVehicle";
            _geoFenceController.sendToVehicle();
        } else {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle GeoFence not supported skipping";
            _sendGeoFenceComplete();
        }
        setDirty(false);
    }
}

void PlanMasterController::_sendGeoFenceComplete(void)
{
    if (_sendRallyPoints) {
        _sendRallyPoints = false;
        if (_rallyPointController.supported()) {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle start rally sendToVehicle";
            _rallyPointController.sendToVehicle();
        } else {
            qCDebug(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle Rally Points not support skipping";
            _sendRallyPointsComplete();
        }
    }
}

void PlanMasterController::_sendRallyPointsComplete(void)
{
    qCDebug(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle Rally Point send complete";
    if (_deleteWhenSendCompleted) {
        this->deleteLater();
    }
}

void PlanMasterController::sendToVehicle(void)
{
    SharedLinkInterfacePtr sharedLink = _managerVehicle->vehicleLinkManager()->primaryLink().lock();
    if (sharedLink) {
        if (sharedLink->linkConfiguration()->isHighLatency()) {
            qgcApp()->showAppMessage(tr("Upload not supported on high latency links."));
            return;
        }
    } else {
        // Vehicle is shutting down
        return;
    }

    if (offline()) {
        qCWarning(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle called while offline";
    } else if (syncInProgress()) {
        qCWarning(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle called while syncInProgress";
    } else {
        qCDebug(PlanMasterControllerLog) << "PlanMasterController::sendToVehicle start mission sendToVehicle";
        _sendGeoFence = true;
        _missionController.sendToVehicle();
        setDirty(false);
    }
}

void PlanMasterController::loadFromFile(const QString& filename)
{
    QString errorString;
    QString errorMessage = tr("Error loading Plan file (%1). %2").arg(filename).arg("%1");

    if (filename.isEmpty()) {
        return;
    }

    QFileInfo fileInfo(filename);
    QFile file(filename);

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        errorString = file.errorString() + QStringLiteral(" ") + filename;
        qgcApp()->showAppMessage(errorMessage.arg(errorString));
        return;
    }

    bool success = false;
    if (fileInfo.suffix() == AppSettings::missionFileExtension) {
        if (!_missionController.loadJsonFile(file, errorString)) {
            qgcApp()->showAppMessage(errorMessage.arg(errorString));
        } else {
            success = true;
        }
    } else if (fileInfo.suffix() == AppSettings::waypointsFileExtension || fileInfo.suffix() == QStringLiteral("txt")) {
        if (!_missionController.loadTextFile(file, errorString)) {
            qgcApp()->showAppMessage(errorMessage.arg(errorString));
        } else {
            success = true;
        }
    } else {
        QJsonDocument   jsonDoc;
        QByteArray      bytes = file.readAll();

        if (!JsonHelper::isJsonFile(bytes, jsonDoc, errorString)) {
            qgcApp()->showAppMessage(errorMessage.arg(errorString));
            return;
        }

        QJsonObject json = jsonDoc.object();
        //-- Allow plugins to pre process the load
        QGCCorePlugin::instance()->preLoadFromJson(this, json);

        int version;
        if (!JsonHelper::validateExternalQGCJsonFile(json, kPlanFileType, kPlanFileVersion, kPlanFileVersion, version, errorString)) {
            qgcApp()->showAppMessage(errorMessage.arg(errorString));
            return;
        }

        QList<JsonHelper::KeyValidateInfo> rgKeyInfo = {
            { kJsonMissionObjectKey,        QJsonValue::Object, true },
            { kJsonGeoFenceObjectKey,       QJsonValue::Object, true },
            { kJsonRallyPointsObjectKey,    QJsonValue::Object, true },
        };
        if (!JsonHelper::validateKeys(json, rgKeyInfo, errorString)) {
            qgcApp()->showAppMessage(errorMessage.arg(errorString));
            return;
        }

        if (!_missionController.load(json[kJsonMissionObjectKey].toObject(), errorString) ||
                !_geoFenceController.load(json[kJsonGeoFenceObjectKey].toObject(), errorString) ||
                !_rallyPointController.load(json[kJsonRallyPointsObjectKey].toObject(), errorString)) {
            qgcApp()->showAppMessage(errorMessage.arg(errorString));
        } else {
            //-- Allow plugins to post process the load
            QGCCorePlugin::instance()->postLoadFromJson(this, json);
            success = true;
        }
    }

    if(success){
        _currentPlanFile = QString::asprintf("%s/%s.%s", fileInfo.path().toLocal8Bit().data(), fileInfo.completeBaseName().toLocal8Bit().data(), AppSettings::planFileExtension);
    } else {
        _currentPlanFile.clear();
    }
    emit currentPlanFileChanged();

    if (!offline()) {
        setDirty(true);
    }
}

QJsonDocument PlanMasterController::saveToJson()
{
    QJsonObject planJson;
    QGCCorePlugin::instance()->preSaveToJson(this, planJson);
    QJsonObject missionJson;
    QJsonObject fenceJson;
    QJsonObject rallyJson;
    JsonHelper::saveQGCJsonFileHeader(planJson, kPlanFileType, kPlanFileVersion);
    //-- Allow plugin to preemptly add its own keys to mission
    QGCCorePlugin::instance()->preSaveToMissionJson(this, missionJson);
    _missionController.save(missionJson);
    //-- Allow plugin to add its own keys to mission
    QGCCorePlugin::instance()->postSaveToMissionJson(this, missionJson);
    _geoFenceController.save(fenceJson);
    _rallyPointController.save(rallyJson);
    planJson[kJsonMissionObjectKey] = missionJson;
    planJson[kJsonGeoFenceObjectKey] = fenceJson;
    planJson[kJsonRallyPointsObjectKey] = rallyJson;
    QGCCorePlugin::instance()->postSaveToJson(this, planJson);
    return QJsonDocument(planJson);
}

void
PlanMasterController::saveToCurrent()
{
    if(!_currentPlanFile.isEmpty()) {
        saveToFile(_currentPlanFile);
    }
}

void PlanMasterController::saveToFile(const QString& filename)
{
    if (filename.isEmpty()) {
        return;
    }

    QString planFilename = filename;
    if (!QFileInfo(filename).fileName().contains(".")) {
        planFilename += QString(".%1").arg(fileExtension());
    }

    QFile file(planFilename);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qgcApp()->showAppMessage(tr("Plan save error %1 : %2").arg(filename).arg(file.errorString()));
        _currentPlanFile.clear();
        emit currentPlanFileChanged();
    } else {
        QJsonDocument saveDoc = saveToJson();
        file.write(saveDoc.toJson());
        if(_currentPlanFile != planFilename) {
            _currentPlanFile = planFilename;
            emit currentPlanFileChanged();
        }
    }

    // Only clear dirty bit if we are offline
    if (offline()) {
        setDirty(false);
    }
}

void PlanMasterController::saveToKml(const QString& filename)
{
    if (filename.isEmpty()) {
        return;
    }

    QString kmlFilename = filename;
    if (!QFileInfo(filename).fileName().contains(".")) {
        kmlFilename += QString(".%1").arg(kmlFileExtension());
    }

    QFile file(kmlFilename);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qgcApp()->showAppMessage(tr("KML save error %1 : %2").arg(filename).arg(file.errorString()));
    } else {
        KMLPlanDomDocument planKML;
        _missionController.addMissionToKML(planKML);
        QTextStream stream(&file);
        stream << planKML.toString();
        file.close();
    }
}

//---------- MÃ CHO NÚT SAVE ----------
void PlanMasterController::saveMissionWaypointsAsJson()
{
    QmlObjectListModel* visualItems = _missionController.visualItems();
    if (!visualItems) return;

            // BƯỚC 1: DUMP TOÀN BỘ KẾ HOẠCH RA MỘT MẢNG JSON TẠM
    QJsonArray fullDataArray;
    for (int i = 0; i < visualItems->count(); i++) {
        VisualMissionItem* vItem = qobject_cast<VisualMissionItem*>(visualItems->get(i));
        if (vItem) {
            vItem->save(fullDataArray);
        }
    }

            // BƯỚC 2: XỬ LÝ MẢNG JSON TẠM
    QJsonArray waypointsArray;
    double missionSpeed = _controllerVehicle ? _controllerVehicle->defaultCruiseSpeed() : -1.0;

    for (int i = 0; i < fullDataArray.count(); i++) {
        QJsonObject itemObject = fullDataArray[i].toObject();
        int command = itemObject["command"].toInt();

                // Chỉ xử lý các item là WAYPOINT
        if (command == 16) { // MAV_CMD_NAV_WAYPOINT
            QJsonObject waypointObject;
            QJsonArray params = itemObject["params"].toArray();

            waypointObject["latitude"]  = params[4];
            waypointObject["longitude"] = params[5];
            waypointObject["altitude"]  = params[6];

            // LOGIC LẤY TỐC ĐỘ: Nhìn về phía trước
            double flightSpeed = missionSpeed;

            if (i + 1 < fullDataArray.count()) {
                QJsonObject nextItemObject = fullDataArray[i + 1].toObject();
                if (nextItemObject["command"].toInt() == 178) {
                    flightSpeed = nextItemObject["params"].toArray()[1].toDouble(missionSpeed);
                }
            }
            waypointObject["flight_speed"] = flightSpeed > 0 ? flightSpeed : QJsonValue::Null;

            // TẠM THỜI ĐẶT is_target LÀ FALSE CHO TẤT CẢ
            waypointObject["is_target"] = false;

            waypointsArray.append(waypointObject);
        }
    }

    // BƯỚC 3: GÁN is_target=true CHO WAYPOINT CUỐI CÙNG
    if (!waypointsArray.isEmpty()) {
        // Lấy ra bản sao của đối tượng cuối cùng
        QJsonObject lastWaypoint = waypointsArray.last().toObject();
        // Sửa đổi bản sao
        lastWaypoint["is_target"] = true;
        // Xóa đối tượng cũ khỏi mảng
        waypointsArray.removeLast();
        // Thêm bản sao đã được sửa đổi vào lại mảng
        waypointsArray.append(lastWaypoint);
    }

            // BƯỚC 4: TẠO VÀ LƯU FILE
    QJsonObject rootObject;
    rootObject["fileType"]  = "FinalPlanWithTarget";
    rootObject["version"]   = 12.0;
    rootObject["waypoints"] = waypointsArray;
    QJsonDocument jsonDocument(rootObject);

    QString jsonFile = QFileDialog::getSaveFileName(nullptr, tr("Save Corrected Plan"), SettingsManager::instance()->appSettings()->missionSavePath(), tr("Plan JSON file (*.json)"));
    if (jsonFile.isEmpty()) return;

    QFile file(jsonFile);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qgcApp()->showAppMessage(tr("Failed to open file for writing: %1").arg(file.errorString()));
        return;
    }

    file.write(jsonDocument.toJson(QJsonDocument::Indented));
    file.close();
    qgcApp()->showAppMessage(tr("Plan saved to %1").arg(jsonFile));
}
//------------ KẾT THÚC MÃ ------------

//==================== BẮT ĐẦU MÃ NGUỒN HÀM SEND ====================
void PlanMasterController::sendSavedPlanToServer()
{
    // 1. Mở hộp thoại để người dùng chọn file JSON
    QString jsonFile = QFileDialog::getOpenFileName(
        nullptr,
        tr("Select Plan JSON File to Send"),
        SettingsManager::instance()->appSettings()->missionSavePath(),
        tr("Simple Plan JSON file (*.json)"));

    if (jsonFile.isEmpty()) {
        // Người dùng đã nhấn Cancel
        return;
    }

            // 2. Đọc nội dung của file đã chọn
    QFile file(jsonFile);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qgcApp()->showAppMessage(tr("Failed to open file for reading: %1").arg(file.errorString()));
        return;
    }
    QByteArray jsonData = file.readAll();
    file.close();

            // 3. Chuẩn bị yêu cầu mạng (Network Request)
    // QUrl url("http://127.0.0.1:5000/submit_plan");
    QUrl url("http://192.168.144.30:5000/submit_plan");
    QNetworkRequest request(url);

    // Đặt header quan trọng
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

            // 4. Gửi yêu cầu POST và xử lý phản hồi
            // Chúng ta cần một QNetworkAccessManager để thực hiện việc này.
            // Tạo một manager mới cho mỗi lần gửi để đảm bảo an toàn luồng (thread-safe).
    QNetworkAccessManager* manager = new QNetworkAccessManager(this);

            // Kết nối tín hiệu 'finished' của reply với một hàm lambda để xử lý khi có phản hồi
    connect(manager, &QNetworkAccessManager::finished, this,
            [=](QNetworkReply* reply)
            {
                // Kiểm tra lỗi mạng
                if (reply->error() != QNetworkReply::NoError)
                {
                    QString errorMessage = tr("Network Error: %1").arg(reply->errorString());
                    qgcApp()->showAppMessage(errorMessage);
                    qCDebug(PlanMasterControllerLog) << errorMessage;
                }
                else
                {
                    // Đọc phản hồi từ server
                    QByteArray responseData = reply->readAll();
                    QJsonDocument jsonResponse = QJsonDocument::fromJson(responseData);

                    if (!jsonResponse.isObject()) {
                        qgcApp()->showAppMessage(tr("Server response is not valid JSON."));
                    } else {
                        QString message = jsonResponse.object()["message"].toString();
                        qgcApp()->showAppMessage(tr("Server Response: %1").arg(message));
                    }
                }

                // Dọn dẹp
                reply->deleteLater();
                manager->deleteLater();
            });

    qgcApp()->showAppMessage(tr("Sending plan to server..."));
    manager->post(request, jsonData);
}
//==================== KẾT THÚC MÃ NGUỒN HÀM SEND ====================

void PlanMasterController::loadMissionFromJson()
{
    // 1. Mở và đọc file JSON tùy chỉnh
    QString jsonFile = QFileDialog::getOpenFileName(
        nullptr,
        tr("Import Custom Plan from JSON file"),
        SettingsManager::instance()->appSettings()->missionSavePath(),
        tr("Custom Plan JSON file (*.json)"));
    if (jsonFile.isEmpty()) return;
    QFile file(jsonFile);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qgcApp()->showAppMessage(tr("Failed to open file for reading: %1").arg(file.errorString()));
        return;
    }
    QByteArray jsonData = file.readAll();
    file.close();

            // 2. Phân tích file JSON tùy chỉnh
    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
    if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject() ||
        !jsonDoc.object().contains("waypoints") || !jsonDoc.object()["waypoints"].isArray()) {
        qgcApp()->showAppMessage(tr("Invalid or corrupted custom plan file."));
        return;
    }
    QJsonArray customWaypointsArray = jsonDoc.object()["waypoints"].toArray();

            // 3. TẠO RA MỘT DANH SÁCH VISUAL ITEM MỚI
    QmlObjectListModel* newVisualItems = new QmlObjectListModel(this);

    // 3b. Thêm item "Takeoff"
    if (!customWaypointsArray.isEmpty()) {
        QJsonObject firstWaypoint = customWaypointsArray[0].toObject();
        if (firstWaypoint.contains("altitude")) {

            // --- LOGIC MỚI ĐỂ LẤY VỊ TRÍ TAKEOFF ---
            QGeoCoordinate takeoffGroundCoord;
            // Ưu tiên 1: Vị trí vehicle hiện tại nếu hợp lệ
            if (_managerVehicle && _managerVehicle->coordinate().isValid()) {
                takeoffGroundCoord = _managerVehicle->coordinate();
            }
            // Ưu tiên 2: Vị trí Home đã lên kế hoạch nếu hợp lệ
            else if (_missionController.plannedHomePosition().isValid()) {
                takeoffGroundCoord = _missionController.plannedHomePosition();
            }
            // Ưu tiên 3 (Dự phòng): Vị trí của waypoint đầu tiên
            else {
                takeoffGroundCoord.setLatitude(firstWaypoint["latitude"].toDouble());
                takeoffGroundCoord.setLongitude(firstWaypoint["longitude"].toDouble());
            }
            // ------------------------------------------

            MissionItem takeoffMissionItem;
            takeoffMissionItem.setCommand(MAV_CMD_NAV_TAKEOFF);
            takeoffMissionItem.setFrame(MAV_FRAME_GLOBAL_RELATIVE_ALT);

            // Gán tọa độ đã được xác định một cách thông minh
            takeoffMissionItem.setParam5(takeoffGroundCoord.latitude());
            takeoffMissionItem.setParam6(takeoffGroundCoord.longitude());
            takeoffMissionItem.setParam7(firstWaypoint["altitude"].toDouble());

            newVisualItems->append(new SimpleMissionItem(this, false, takeoffMissionItem));
        }
    }

    // 3c. Lặp qua file JSON và tạo các item tương ứng
    double lastSpeed = -1.0;
    for (const QJsonValue &value : customWaypointsArray)
    {
        QJsonObject wpObject = value.toObject();

        MissionItem waypointMissionItem;
        waypointMissionItem.setCommand(MAV_CMD_NAV_WAYPOINT);
        waypointMissionItem.setFrame(MAV_FRAME_GLOBAL_RELATIVE_ALT);
        waypointMissionItem.setParam4(NAN);
        waypointMissionItem.setParam5(wpObject["latitude"].toDouble());
        waypointMissionItem.setParam6(wpObject["longitude"].toDouble());
        waypointMissionItem.setParam7(wpObject["altitude"].toDouble());
        newVisualItems->append(new SimpleMissionItem(this, false, waypointMissionItem));

        if (wpObject.contains("flight_speed") && wpObject["flight_speed"].isDouble()) {
            double flightSpeed = wpObject["flight_speed"].toDouble();
            if (flightSpeed >= 0 && flightSpeed != lastSpeed) {
                MissionItem speedMissionItem;
                speedMissionItem.setCommand(MAV_CMD_DO_CHANGE_SPEED);
                speedMissionItem.setFrame(MAV_FRAME_MISSION);
                speedMissionItem.setParam1(1);
                speedMissionItem.setParam2(flightSpeed);
                speedMissionItem.setParam3(-1);
                newVisualItems->append(new SimpleMissionItem(this, false, speedMissionItem));
                lastSpeed = flightSpeed;
            }
        }
    }

            // 4. GỌI HÀM CỦA MISSIONCONTROLLER ĐỂ THAY THẾ TOÀN BỘ KẾ HOẠCH
    QJsonObject qgcMissionObject;
    QJsonArray qgcItemsJsonArray;
    for(int i=0; i<newVisualItems->count(); i++) {
        QJsonArray itemJson;
        qobject_cast<VisualMissionItem*>(newVisualItems->get(i))->save(itemJson);
        for(const QJsonValue& val : itemJson) {
            qgcItemsJsonArray.append(val);
        }
    }
    QGeoCoordinate homePos = _managerVehicle ? _managerVehicle->homePosition() : QGeoCoordinate();
    qgcMissionObject["plannedHomePosition"] = QJsonArray{ homePos.latitude(), homePos.longitude(), homePos.altitude() };
    qgcMissionObject["items"] = qgcItemsJsonArray;
    qgcMissionObject["firmwareType"] = _managerVehicle->firmwareType();
    qgcMissionObject["vehicleType"] = _managerVehicle->vehicleType();

    QString errorString;
    if (!_missionController.load(qgcMissionObject, errorString)) {
        qgcApp()->showAppMessage(tr("Failed to load converted plan: %1").arg(errorString));
    } else {
        qgcApp()->showAppMessage(tr("Plan import successful."));
    }

    newVisualItems->deleteLater();
}

//==================== BẮT ĐẦU MÃ NGUỒN CHO SERIAL PORT ====================
bool PlanMasterController::isSerialActive() const
{
    return _serialPort && _serialPort->isOpen();
}

QStringList PlanMasterController::getAvailableSerialPorts()
{
    QStringList portList;
    const auto portInfos = QSerialPortInfo::availablePorts();

    qCDebug(PlanMasterControllerLog) << "Scanning for available serial ports...";

    for (const QSerialPortInfo &info : portInfos) {
        QString name = info.portName();

        // Chỉ thêm vào danh sách nếu tên cổng bắt đầu bằng "ttyUSB" hoặc "ttyACM"
        if (name.startsWith("ttyUSB") || name.startsWith("ttyACM")) {
            portList.append(name);
            qCDebug(PlanMasterControllerLog) << "  > Found relevant port:" << name;
        } else {
            qCDebug(PlanMasterControllerLog) << "  > Skipping irrelevant port:" << name;
        }
    }

    if (portList.isEmpty()) {
        qCDebug(PlanMasterControllerLog) << "No relevant serial ports (ttyUSB*, ttyACM*) found.";
    }

    return portList;
}

bool PlanMasterController::startSerialListener(const QString& portName, int baudRate)
{
    if (!_serialPort) {
        qCWarning(PlanMasterControllerLog) << "Serial port object is null.";
        return false;
    }

    if (_serialPort->isOpen()) {
        qCWarning(PlanMasterControllerLog) << "Serial port is already open.";
        return true;
    }

    _serialPort->setPortName(portName);
    _serialPort->setBaudRate(baudRate);
    // Các cài đặt khác có thể giữ mặc định (Data8, NoParity, OneStop)

    if (_serialPort->open(QIODevice::ReadOnly)) {
        connect(_serialPort, &QSerialPort::readyRead, this, &PlanMasterController::_onSerialDataReady);
        qCDebug(PlanMasterControllerLog) << "Successfully opened serial port" << portName << "at" << baudRate << "baud.";
        emit isSerialActiveChanged();
        return true;
    } else {
        qCWarning(PlanMasterControllerLog) << "Failed to open serial port" << portName << ":" << _serialPort->errorString();
        qgcApp()->showAppMessage(tr("Failed to open serial port %1: %2").arg(portName).arg(_serialPort->errorString()));
        return false;
    }
}

void PlanMasterController::stopSerialListener()
{
    if (_serialPort && _serialPort->isOpen()) {
        _serialPort->close();
        qCDebug(PlanMasterControllerLog) << "Serial port closed.";
        emit isSerialActiveChanged();
    }
}

void PlanMasterController::_onSerialDataReady()
{
    // Đọc tất cả dữ liệu có sẵn và nối vào buffer
    _serialBuffer.append(_serialPort->readAll());

            // Xử lý buffer để tìm các gói tin hoàn chỉnh (kết thúc bằng '\n')
    while (_serialBuffer.contains('\n')) {
        int newlineIndex = _serialBuffer.indexOf('\n');
        // Lấy ra gói tin (không bao gồm ký tự '\n')
        QByteArray packet = _serialBuffer.left(newlineIndex);
        // Xóa gói tin đã xử lý và ký tự '\n' khỏi buffer
        _serialBuffer.remove(0, newlineIndex + 1);

                // Chỉ xử lý nếu gói tin có đúng 10 ký tự
        if (packet.length() == 10) {
            QString rawData = QString::fromLatin1(packet);
            qCDebug(PlanMasterControllerLog) << "Serial packet received:" << rawData;

            // Gửi dữ liệu thô lên server
            QUrl url("http://192.168.144.30:5000/submit_button_states"); // Sử dụng endpoint mới
            QNetworkRequest request(url);
            request.setHeader(QNetworkRequest::ContentTypeHeader, "text/plain");

                    // Gửi và quên đi, không cần xử lý phản hồi phức tạp cho mỗi gói tin
            _networkManager->post(request, rawData.toUtf8());

        } else {
            qCWarning(PlanMasterControllerLog) << "Received malformed serial packet, length:" << packet.length() << "Content:" << QString::fromLatin1(packet);
        }
    }
}
//==================== KẾT THÚC MÃ NGUỒN CHO SERIAL PORT ====================

void PlanMasterController::removeAll(void)
{
    _missionController.removeAll();
    _geoFenceController.removeAll();
    _rallyPointController.removeAll();
    if (_offline) {
        _missionController.setDirty(false);
        _geoFenceController.setDirty(false);
        _rallyPointController.setDirty(false);
        _currentPlanFile.clear();
        emit currentPlanFileChanged();
    }
}

void PlanMasterController::removeAllFromVehicle(void)
{
    if (!offline()) {
        _missionController.removeAllFromVehicle();
        if (_geoFenceController.supported()) {
            _geoFenceController.removeAllFromVehicle();
        }
        if (_rallyPointController.supported()) {
            _rallyPointController.removeAllFromVehicle();
        }
        setDirty(false);
    } else {
        qWarning() << "PlanMasterController::removeAllFromVehicle called while offline";
    }
}

bool PlanMasterController::containsItems(void) const
{
    return _missionController.containsItems() || _geoFenceController.containsItems() || _rallyPointController.containsItems();
}

bool PlanMasterController::dirty(void) const
{
    return _missionController.dirty() || _geoFenceController.dirty() || _rallyPointController.dirty();
}

void PlanMasterController::setDirty(bool dirty)
{
    _missionController.setDirty(dirty);
    _geoFenceController.setDirty(dirty);
    _rallyPointController.setDirty(dirty);
}

QString PlanMasterController::fileExtension(void) const
{
    return AppSettings::planFileExtension;
}

QString PlanMasterController::kmlFileExtension(void) const
{
    return AppSettings::kmlFileExtension;
}

QStringList PlanMasterController::loadNameFilters(void) const
{
    QStringList filters;

    filters << tr("Supported types (*.%1 *.%2 *.%3 *.%4)").arg(AppSettings::planFileExtension).arg(AppSettings::missionFileExtension).arg(AppSettings::waypointsFileExtension).arg("txt") <<
               tr("All Files (*)");
    return filters;
}


QStringList PlanMasterController::saveNameFilters(void) const
{
    QStringList filters;

    filters << tr("Plan Files (*.%1)").arg(fileExtension()) << tr("All Files (*)");
    return filters;
}

void PlanMasterController::sendPlanToVehicle(Vehicle* vehicle, const QString& filename)
{
    // Use a transient PlanMasterController to accomplish this
    PlanMasterController* controller = new PlanMasterController();
    controller->startStaticActiveVehicle(vehicle, true /* deleteWhenSendCompleted */);
    controller->loadFromFile(filename);
    controller->sendToVehicle();
}

void PlanMasterController::_showPlanFromManagerVehicle(void)
{
    if (!_managerVehicle->initialPlanRequestComplete() && !syncInProgress()) {
        // Something went wrong with initial load. All controllers are idle, so just force it off
        _managerVehicle->forceInitialPlanRequestComplete();
    }

    // The crazy if structure is to handle the load propagating by itself through the system
    if (!_missionController.showPlanFromManagerVehicle()) {
        if (!_geoFenceController.showPlanFromManagerVehicle()) {
            _rallyPointController.showPlanFromManagerVehicle();
        }
    }
}

bool PlanMasterController::syncInProgress(void) const
{
    return _missionController.syncInProgress() ||
            _geoFenceController.syncInProgress() ||
            _rallyPointController.syncInProgress();
}

bool PlanMasterController::isEmpty(void) const
{
    return _missionController.isEmpty() &&
            _geoFenceController.isEmpty() &&
            _rallyPointController.isEmpty();
}

void PlanMasterController::_updateOverallDirty(void)
{
    if(_previousOverallDirty != dirty()){
        _previousOverallDirty = dirty();
        emit dirtyChanged(_previousOverallDirty);
    }    
}

void PlanMasterController::_updatePlanCreatorsList(void)
{
    if (!_flyView) {
        if (!_planCreators) {
            _planCreators = new QmlObjectListModel(this);
            _planCreators->append(new BlankPlanCreator(this, this));
            _planCreators->append(new SurveyPlanCreator(this, this));
            _planCreators->append(new CorridorScanPlanCreator(this, this));
            emit planCreatorsChanged(_planCreators);
        }

        if (_managerVehicle->fixedWing()) {
            if (_planCreators->count() == 4) {
                _planCreators->removeAt(_planCreators->count() - 1);
            }
        } else {
            if (_planCreators->count() != 4) {
                _planCreators->append(new StructureScanPlanCreator(this, this));
            }
        }
    }
}

void PlanMasterController::showPlanFromManagerVehicle(void)
{
    if (offline()) {
        // There is no new vehicle so clear any previous plan
        qCDebug(PlanMasterControllerLog) << "showPlanFromManagerVehicle: Plan View - No new vehicle, clear any previous plan";
        removeAll();
    } else {
        // We have a new active vehicle, show the plan from that
        qCDebug(PlanMasterControllerLog) << "showPlanFromManagerVehicle: Plan View - New vehicle available, show plan from new manager vehicle";
        _showPlanFromManagerVehicle();
    }
}
