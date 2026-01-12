#pragma once

#include <QObject>
#include <QtSerialPort/QSerialPort>
#include <QtQml/qqmlregistration.h> // ✅ add this

class SerialController : public QObject
{
    Q_OBJECT
QML_ELEMENT // ✅ this is the key for qt_add_qml_module auto-registration

Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
        Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)

            public : explicit SerialController(QObject *parent = nullptr);

    bool connected() const { return m_serial.isOpen(); }

    QString portName() const { return m_portName; }
    void setPortName(const QString &name);

    int baudRate() const { return m_baudRate; }
    void setBaudRate(int baud);

    Q_INVOKABLE bool connectPort();
    Q_INVOKABLE void disconnectPort();
    Q_INVOKABLE void sendPing();
    Q_INVOKABLE void sendLine(const QString &line);

signals:
    void connectedChanged();
    void portNameChanged();
    void baudRateChanged();
    void lineReceived(const QString &line);
    void error(const QString &message);

private:
    QSerialPort m_serial;
    QByteArray m_rxBuffer;
    QString m_portName = "/dev/ttyAMA3";
    int m_baudRate = 115200;
};
