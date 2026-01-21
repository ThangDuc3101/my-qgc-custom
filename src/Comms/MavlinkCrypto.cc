/****************************************************************************
 *
 * MAVLink Encryption/Decryption support for QGroundControl
 *
 ****************************************************************************/

#include "MavlinkCrypto.h"
#include "QGCLoggingCategory.h"

#include <QtCore/qapplicationstatic.h>

QGC_LOGGING_CATEGORY(MavlinkCryptoLog, "qgc.comms.mavlinkcrypto")

Q_APPLICATION_STATIC(MavlinkCrypto, _mavlinkCryptoInstance);

MavlinkCrypto::MavlinkCrypto(QObject *parent)
    : QObject(parent)
{
    // TEMPORARY: Hardcoded test key for debugging (matches PX4)
    // Key bytes: 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20
    _key.resize(32);
    for (int i = 0; i < 32; i++) {
        _key[i] = static_cast<char>(i + 1);
    }
    _enabled = true;  // TEMPORARY: Auto-enable for testing - remove for production
    qCInfo(MavlinkCryptoLog) << "MavlinkCrypto initialized with HARDCODED TEST KEY, encryption AUTO-ENABLED";
}



MavlinkCrypto* MavlinkCrypto::instance()
{
    return _mavlinkCryptoInstance();
}

void MavlinkCrypto::setKey(const QByteArray &key)
{
    if (key.size() >= 32) {
        _key = key.left(32);
        qCDebug(MavlinkCryptoLog) << "Encryption key set";
    } else if (key.size() > 0) {
        // Pad with zeros if key is smaller
        _key = key;
        _key.append(QByteArray(32 - key.size(), 0));
        qCWarning(MavlinkCryptoLog) << "Key size less than 32 bytes, padding with zeros";
    } else {
        _key.fill(0, 32);
    }
}

void MavlinkCrypto::setEnabled(bool enabled)
{
    if (_enabled != enabled) {
        _enabled = enabled;
        qCInfo(MavlinkCryptoLog) << "MAVLink encryption" << (enabled ? "enabled" : "disabled");
    }
}

QByteArray MavlinkCrypto::encrypt(const QByteArray &plaintext)
{
    if (!_enabled || plaintext.isEmpty()) {
        return plaintext;
    }

    qCDebug(MavlinkCryptoLog) << "Encrypting" << plaintext.size() << "bytes, key[0-3]:" 
                              << QString::number((uint8_t)_key[0], 16)
                              << QString::number((uint8_t)_key[1], 16)
                              << QString::number((uint8_t)_key[2], 16)
                              << QString::number((uint8_t)_key[3], 16);

    QByteArray ciphertext(plaintext.size(), 0);

    // Simple XOR encryption with fixed byte to avoid fragmentation issues
    // When data arrives in chunks, index-based XOR breaks alignment
    const uint8_t xorByte = _key[0];
    for (int i = 0; i < plaintext.size(); i++) {
        ciphertext[i] = plaintext[i] ^ xorByte;
    }

    _txNonce++;
    return ciphertext;
}

QByteArray MavlinkCrypto::decrypt(const QByteArray &ciphertext)
{
    if (!_enabled || ciphertext.isEmpty()) {
        return ciphertext;
    }

    qCDebug(MavlinkCryptoLog) << "Decrypting" << ciphertext.size() << "bytes, key[0-3]:"
                              << QString::number((uint8_t)_key[0], 16)
                              << QString::number((uint8_t)_key[1], 16)
                              << QString::number((uint8_t)_key[2], 16)
                              << QString::number((uint8_t)_key[3], 16);

    QByteArray plaintext(ciphertext.size(), 0);

    // Simple XOR decryption with fixed byte to avoid fragmentation issues
    const uint8_t xorByte = _key[0];
    for (int i = 0; i < ciphertext.size(); i++) {
        plaintext[i] = ciphertext[i] ^ xorByte;
    }

    _rxNonce++;
    return plaintext;
}

