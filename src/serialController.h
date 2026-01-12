#pragma once

#include <QObject>
#include <QtSerialPort/QSerialPort>

class SerialController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)

public:
    explicit SerialController(QObject *parent = nullptr);

    bool connected() const { return m_serial.isOpen(); }

    QString portName() const { return m_portName; }
    void setPortName(const QString &name);

    int baudRate() const { return m_baudRate; }
    void setBaudRate(int baud);

    Q_INVOKABLE bool connectPort(); // opens + configures port
    Q_INVOKABLE void disconnectPort();
    Q_INVOKABLE void sendPing();                    // sends "PING\r\n"
    Q_INVOKABLE void sendLine(const QString &line); // sends "<line>\r\n"

signals:
    void connectedChanged();
    void portNameChanged();
    void baudRateChanged();

    void lineReceived(const QString &line);
    void error(const QString &message);

private slots:
    void onReadyRead();
    void onSerialError(QSerialPort::SerialPortError e);

private:
    void emitError(const QString &msg);
    void applySettings();

    QSerialPort m_serial;
    QByteArray m_rxBuffer;

    QString m_portName = "/dev/ttyAMA3";
    int m_baudRate = 115200;
};
