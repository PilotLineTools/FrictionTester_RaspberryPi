#pragma once
#include <QObject>
#include <QSerialPort>
#include <QTimer>

class UartClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString portName READ portName WRITE setPortName NOTIFY portNameChanged)
    Q_PROPERTY(int baudRate READ baudRate WRITE setBaudRate NOTIFY baudRateChanged)

public:
    explicit UartClient(QObject *parent = nullptr);

    bool connected() const { return m_serial.isOpen(); }

    QString portName() const { return m_portName; }
    void setPortName(const QString &name);

    int baudRate() const { return m_baudRate; }
    void setBaudRate(int b);

    Q_INVOKABLE bool connectPort();
    Q_INVOKABLE void disconnectPort();
    Q_INVOKABLE void sendLine(const QString &line);

signals:
    void connectedChanged();
    void portNameChanged();
    void baudRateChanged();
    void lineReceived(const QString &line);
    void errorText(const QString &msg);

private slots:
    void onReadyRead();
    void onError(QSerialPort::SerialPortError err);

private:
    QSerialPort m_serial;
    QByteArray m_buf;
    QString m_portName = "/dev/ttyAMA3"; // your Pi GPIO4/5 UART
    int m_baudRate = 115200;
};
