import os
import sys
from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtSerialPort import QSerialPort


class SerialController(QObject):
    connectedChanged = Signal()
    lineReceived = Signal(str)
    error = Signal(str)

    def __init__(self):
        super().__init__()
        self._serial = QSerialPort()
        self._port_name = "/dev/ttyAMA3"
        self._baud = 115200
        self._rx = bytearray()

        self._apply_settings()
        self._serial.readyRead.connect(self._on_ready_read)

    def _apply_settings(self):
        self._serial.setPortName(self._port_name)
        self._serial.setBaudRate(self._baud)
        self._serial.setDataBits(QSerialPort.Data8)
        self._serial.setParity(QSerialPort.NoParity)
        self._serial.setStopBits(QSerialPort.OneStop)
        self._serial.setFlowControl(QSerialPort.NoFlowControl)

    def _on_ready_read(self):
        data = bytes(self._serial.readAll())
        if data:
            print("RAW RX:", data)   # 🔍 DEBUG — keep this for now
        self._rx.extend(data)

        while True:
            idx = self._rx.find(b"\n")
            if idx < 0:
                break

            line = self._rx[:idx]
            del self._rx[:idx + 1]

            text = line.decode("utf-8", errors="replace").rstrip("\r")
            print("RX LINE:", text)   # 🔍 DEBUG

            self.lineReceived.emit(text)

    def get_connected(self):
        return self._serial.isOpen()

    connected = Property(bool, get_connected, notify=connectedChanged)

    def get_portName(self):
        return self._port_name

    def set_portName(self, v):
        if self._port_name == v:
            return
        self._port_name = v
        if self._serial.isOpen():
            self.disconnectPort()
        self._apply_settings()
        self.portNameChanged.emit()

    portNameChanged = Signal()
    portName = Property(str, get_portName, set_portName, notify=portNameChanged)

    def get_baudRate(self):
        return self._baud

    def set_baudRate(self, v):
        if self._baud == v:
            return
        self._baud = int(v)
        if self._serial.isOpen():
            self.disconnectPort()
        self._apply_settings()
        self.baudRateChanged.emit()

    baudRateChanged = Signal()
    baudRate = Property(int, get_baudRate, set_baudRate, notify=baudRateChanged)

    @Slot(result=bool)
    def connectPort(self):
        if self._serial.isOpen():
            return True
        ok = self._serial.open(QSerialPort.ReadWrite)
 
        print("OPEN OK?", ok, "ERR:", self._serial.errorString())

        if not ok:
            self.error.emit(self._serial.errorString())
        self.connectedChanged.emit()
        return ok

    @Slot()
    def disconnectPort(self):
        if self._serial.isOpen():
            self._serial.close()
            self.connectedChanged.emit()

    @Slot(str)
    def sendLine(self, line: str):
        if not self._serial.isOpen():
            self.error.emit("Serial not open. Call connectPort() first.")
            return
        self._serial.write((line + "\r\n").encode("utf-8"))  # matches echo -ne "PING\r\n"

    @Slot()
    def sendPing(self):
        self.sendLine("PING")


def main():
    # Kiosk settings (optional)
    os.environ.setdefault("QT_QPA_PLATFORM", "eglfs")
    os.environ.setdefault("QT_QPA_EGLFS_HIDECURSOR", "1")

    # Make sure QML can find your local modules (same as your script)
    project_dir = os.path.dirname(os.path.abspath(__file__))
    qml_imports = [
        os.path.join(project_dir, "imports"),
        os.path.join(project_dir, "content"),
        os.path.join(project_dir, "qmlmodules"),
    ]
    os.environ["QML_IMPORT_PATH"] = ":".join(qml_imports)

    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    serial = SerialController()
    engine.rootContext().setContextProperty("serialController", serial)

    app_qml = os.path.join(project_dir, "content", "App.qml")
    engine.load(QUrl.fromLocalFile(app_qml))

    if not engine.rootObjects():
        return 1

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
