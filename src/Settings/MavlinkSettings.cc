
/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "MavlinkSettings.h"
#include "LinkManager.h"
#include "MavlinkCrypto.h"

DECLARE_SETTINGGROUP(Mavlink, "")
{
    // Move deprecated settings to new location/names

    QSettings deprecatedSettings;
    QSettings newSettings;

    newSettings.beginGroup(_settingsGroup);

    static const char* deprecatedGCSHeartbeatEnabledKey = "gcsHeartbeatEnabled";
    if (!newSettings.contains(sendGCSHeartbeatName) && deprecatedSettings.contains(deprecatedGCSHeartbeatEnabledKey)) {
        newSettings.setValue(sendGCSHeartbeatName, deprecatedSettings.value(deprecatedGCSHeartbeatEnabledKey));
        deprecatedSettings.remove(deprecatedGCSHeartbeatEnabledKey);
    }

    static const char* deprecatedMavlinkGroup = "QGC_MAVLINK_PROTOCOL";
    static const char* deprecatedMavlinkSystemIdKey = "GCS_SYSTEM_ID";
    deprecatedSettings.beginGroup(deprecatedMavlinkGroup);
    if (!newSettings.contains(gcsMavlinkSystemIDName) && deprecatedSettings.contains(deprecatedMavlinkSystemIdKey)) {
        newSettings.setValue(gcsMavlinkSystemIDName, deprecatedSettings.value(deprecatedMavlinkSystemIdKey));
        deprecatedSettings.remove(deprecatedMavlinkSystemIdKey);
    }

    newSettings.endGroup();
    deprecatedSettings.endGroup();
}

DECLARE_SETTINGSFACT(MavlinkSettings, telemetrySave)
DECLARE_SETTINGSFACT(MavlinkSettings, telemetrySaveNotArmed)
DECLARE_SETTINGSFACT(MavlinkSettings, apmStartMavlinkStreams)
DECLARE_SETTINGSFACT(MavlinkSettings, saveCsvTelemetry)
DECLARE_SETTINGSFACT(MavlinkSettings, forwardMavlink)
DECLARE_SETTINGSFACT(MavlinkSettings, forwardMavlinkHostName)
DECLARE_SETTINGSFACT(MavlinkSettings, forwardMavlinkAPMSupportHostName)
DECLARE_SETTINGSFACT(MavlinkSettings, sendGCSHeartbeat)
DECLARE_SETTINGSFACT(MavlinkSettings, gcsMavlinkSystemID)
DECLARE_SETTINGSFACT(MavlinkSettings, requireMatchingMavlinkVersions)

DECLARE_SETTINGSFACT_NO_FUNC(MavlinkSettings, mavlink2SigningKey)
{
    if (!_mavlink2SigningKeyFact) {
        _mavlink2SigningKeyFact = _createSettingsFact(mavlink2SigningKeyName);
        connect(_mavlink2SigningKeyFact, &Fact::rawValueChanged, this, &MavlinkSettings::_mavlink2SigningKeyChanged);
    }
    return _mavlink2SigningKeyFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(MavlinkSettings, encryptionEnabled)
{
    if (!_encryptionEnabledFact) {
        _encryptionEnabledFact = _createSettingsFact(encryptionEnabledName);
        connect(_encryptionEnabledFact, &Fact::rawValueChanged, this, &MavlinkSettings::_encryptionSettingsChanged);
        // Apply initial value
        MavlinkCrypto::instance()->setEnabled(_encryptionEnabledFact->rawValue().toBool());
    }
    return _encryptionEnabledFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(MavlinkSettings, encryptionKey)
{
    if (!_encryptionKeyFact) {
        _encryptionKeyFact = _createSettingsFact(encryptionKeyName);
        connect(_encryptionKeyFact, &Fact::rawValueChanged, this, &MavlinkSettings::_encryptionSettingsChanged);
        // Apply initial value
        _encryptionSettingsChanged();
    }
    return _encryptionKeyFact;
}

void MavlinkSettings::_mavlink2SigningKeyChanged(void)
{
    LinkManager::instance()->resetMavlinkSigning();
}

void MavlinkSettings::_encryptionSettingsChanged(void)
{
    // TEMPORARY: During testing with hardcoded key, only control enable/disable
    // The key is hardcoded in MavlinkCrypto constructor for testing
    // Uncomment the key code below when switching to production key input
    
    /*
    // Get key from hex string
    QString keyHex = _encryptionKeyFact ? _encryptionKeyFact->rawValue().toString() : QString();
    QByteArray key = QByteArray::fromHex(keyHex.toLatin1());
    
    // Pad to 32 bytes if necessary
    if (key.size() < 32) {
        key.append(QByteArray(32 - key.size(), '\0'));
    } else if (key.size() > 32) {
        key = key.left(32);
    }
    
    MavlinkCrypto::instance()->setKey(key);
    */
    
    bool enabled = _encryptionEnabledFact ? _encryptionEnabledFact->rawValue().toBool() : false;
    MavlinkCrypto::instance()->setEnabled(enabled);
}
