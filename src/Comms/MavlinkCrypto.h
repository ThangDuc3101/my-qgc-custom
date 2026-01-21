/****************************************************************************
 *
 * MAVLink Encryption/Decryption support for QGroundControl
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QByteArray>
#include <QtCore/QObject>

/// Simple XOR-based encryption for MAVLink communication
/// TODO: Replace with XChaCha20-Poly1305 for production use
class MavlinkCrypto : public QObject
{
    Q_OBJECT

public:
    static MavlinkCrypto* instance();
    explicit MavlinkCrypto(QObject *parent = nullptr);

    /// Set the encryption key (32 bytes)
    void setKey(const QByteArray &key);

    /// Enable or disable encryption
    void setEnabled(bool enabled);

    /// Check if encryption is enabled
    bool isEnabled() const { return _enabled; }

    /// Encrypt data for sending to vehicle
    QByteArray encrypt(const QByteArray &plaintext);

    /// Decrypt data received from vehicle
    QByteArray decrypt(const QByteArray &ciphertext);

private:

    bool _enabled = false;
    QByteArray _key;
    uint64_t _txNonce = 0;
    uint64_t _rxNonce = 0;
};
