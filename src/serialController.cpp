#include "SerialController.h"
#include <QDebug>

SerialController::SerialController(QObject *parent)
    : QObject(parent)
{
    serial.setPortName("/dev/ttyAMA3");
    serial.setBaudRate(QSerialPort::Baud115200);
    serial.setDataBits(QSerialPort::Data8);
    serial.setParity(QSerialPort::NoParity);
    serial.setStopBits(QSerialPort::OneStop);
    serial.setFlowControl(QSerialPort::NoFlowControl);

    if (!serial.open(QIODevice::ReadWrite)) {
        qWarning() << "Failed to open serial port:" << serial.errorString();
    } else {
        qDebug() << "Serial port opened";
    }
}

void SerialController::sendPing()
{
    if (!serial.isOpen()) {
        qWarning() << "Serial not open";
        return;
    }

    QByteArray data = "PING\r\n";
    serial.write(data);
    serial.flush();

    qDebug() << "PING sent";
}
