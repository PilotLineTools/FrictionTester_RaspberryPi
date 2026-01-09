#include "UartClient.h"

UartClient::UartClient(QObject *parent) : QObject(parent)
{
    connect(&m_serial, &QSerialPort::readyRead, this, &UartClient::onReadyRead);
    connect(&m_serial, &QSerialPort::errorOccurred, this, &UartClient::onError);
}

void UartClient::setPortName(const QString &name)
{
    if (m_portName == name)
        return;
    m_portName = name;
    emit portNameChanged();
}

void UartClient::setBaudRate(int b)
{
    if (m_baudRate == b)
        return;
    m_baudRate = b;
    emit baudRateChanged();
}

bool UartClient::connectPort()
{
    if (m_serial.isOpen())
        return true;

    m_serial.setPortName(m_portName);
    m_serial.setBaudRate(m_baudRate);
    m_serial.setDataBits(QSerialPort::Data8);
    m_serial.setParity(QSerialPort::NoParity);
    m_serial.setStopBits(QSerialPort::OneStop);
    m_serial.setFlowControl(QSerialPort::NoFlowControl);

    if (!m_serial.open(QIODevice::ReadWrite))
    {
        emit errorText("Open failed: " + m_serial.errorString());
        emit connectedChanged();
        return false;
    }

    emit connectedChanged();
    return true;
}

void UartClient::disconnectPort()
{
    if (!m_serial.isOpen())
        return;
    m_serial.close();
    emit connectedChanged();
}

void UartClient::sendLine(const QString &line)
{
    if (!m_serial.isOpen())
    {
        emit errorText("UART not connected");
        return;
    }
    QByteArray out = line.toUtf8();
    if (!out.endsWith('\n'))
        out.append('\n');
    m_serial.write(out);
}

void UartClient::onReadyRead()
{
    m_buf.append(m_serial.readAll());
    while (true)
    {
        int idx = m_buf.indexOf('\n');
        if (idx < 0)
            break;
        QByteArray line = m_buf.left(idx);
        m_buf.remove(0, idx + 1);
        line = line.trimmed();
        if (!line.isEmpty())
            emit lineReceived(QString::fromUtf8(line));
    }
}

void UartClient::onError(QSerialPort::SerialPortError err)
{
    if (err == QSerialPort::NoError)
        return;
    emit errorText("UART error: " + m_serial.errorString());
}
