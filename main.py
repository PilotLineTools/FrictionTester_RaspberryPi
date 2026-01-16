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
        """
        Initialize the SerialController with default serial port settings.
        
        Sets up the serial port connection with default values:
        - Port: /dev/ttyAMA3 (Raspberry Pi GPIO UART)
        - Baud rate: 115200
        - Data bits: 8
        - Parity: None
        - Stop bits: 1
        - Flow control: None
        
        Connects the readyRead signal to handle incoming data automatically.
        """
        super().__init__()
        self._serial = QSerialPort()
        self._port_name = "/dev/ttyAMA3"
        self._baud = 115200
        self._rx = bytearray()

        self._apply_settings()
        self._serial.readyRead.connect(self._on_ready_read)

    def _apply_settings(self):
        """
        Apply current serial port configuration settings to the QSerialPort instance.
        
        This private method updates all serial port parameters (port name, baud rate,
        data bits, parity, stop bits, and flow control) based on the current
        instance variables. Called whenever port settings change.
        """
        self._serial.setPortName(self._port_name)
        self._serial.setBaudRate(self._baud)
        self._serial.setDataBits(QSerialPort.Data8)
        self._serial.setParity(QSerialPort.NoParity)
        self._serial.setStopBits(QSerialPort.OneStop)
        self._serial.setFlowControl(QSerialPort.NoFlowControl)

    def _on_ready_read(self):
        """
        Handle incoming serial data when readyRead signal is emitted.
        
        Reads all available data from the serial port, buffers it, and processes
        complete lines (terminated by newline). Each complete line is decoded from
        UTF-8, stripped of carriage return characters, and emitted via the
        lineReceived signal for processing by QML or other handlers.
        
        Uses a buffer to handle partial lines that may arrive across multiple
        read operations.
        """
        data = bytes(self._serial.readAll())

        # View raw data for debugging
        #if data:
        #    print("RAW RX:", data)   # 🔍 DEBUG — keep this for now
        
        self._rx.extend(data)

        while True:
            idx = self._rx.find(b"\n")
            if idx < 0:
                break

            line = self._rx[:idx]
            del self._rx[:idx + 1]

            text = line.decode("utf-8", errors="replace").rstrip("\r")
            #print("RX LINE:", text)   # 🔍 DEBUG

            self.lineReceived.emit(text)

    def get_connected(self):
        """
        Get the current connection status of the serial port.
        
        Returns:
            bool: True if the serial port is open, False otherwise.
        """
        return self._serial.isOpen()

    connected = Property(bool, get_connected, notify=connectedChanged)

    def get_portName(self):
        """
        Get the current serial port name.
        
        Returns:
            str: The port name (e.g., "/dev/ttyAMA3").
        """
        return self._port_name

    def set_portName(self, v):
        """
        Set the serial port name.
        
        If the port is currently open, it will be closed before applying the new
        port name. The port must be reconnected after changing the port name.
        
        Args:
            v (str): The new port name to use.
        """
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
        """
        Get the current baud rate setting.
        
        Returns:
            int: The baud rate (e.g., 115200).
        """
        return self._baud

    def set_baudRate(self, v):
        """
        Set the serial port baud rate.
        
        If the port is currently open, it will be closed before applying the new
        baud rate. The port must be reconnected after changing the baud rate.
        
        Args:
            v (int): The new baud rate to use.
        """
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
        """
        Open and connect to the serial port.
        
        Attempts to open the serial port in ReadWrite mode. If the port is
        already open, returns True immediately. Emits error signal if connection
        fails, and connectedChanged signal in all cases.
        
        Returns:
            bool: True if connection was successful or already connected,
                  False if connection failed.
        """
        if self._serial.isOpen():
            return True
        ok = self._serial.open(QSerialPort.ReadWrite)
 
        #print("OPEN OK?", ok, "ERR:", self._serial.errorString())

        if not ok:
            self.error.emit(self._serial.errorString())
        self.connectedChanged.emit()
        return ok

    @Slot()
    def disconnectPort(self):
        """
        Close and disconnect from the serial port.
        
        Closes the serial port if it is currently open and emits the
        connectedChanged signal to notify listeners of the disconnection.
        """
        if self._serial.isOpen():
            self._serial.close()
            self.connectedChanged.emit()

    @Slot(str)
    def send_cmd(self, cmd: str):
        """
        Send a command string to the serial port.
        
        Encodes the command as UTF-8 and appends "\r\n" (carriage return + newline)
        to match the expected command format. Emits an error signal if the port
        is not open.
        
        Args:
            cmd (str): The command string to send (without line endings).
        """
        if not self._serial.isOpen():
            self.error.emit("Serial not open. Call connectPort() first.")
            return
        self._serial.write((cmd + "\r\n").encode("utf-8"))  # matches echo -ne "PING\r\n"

    @Slot()
    def sendPing(self):
        """
        Send a PING command to the ESP32 device.
        
        This is a convenience method that sends "PING" to check communication
        and device responsiveness.
        """
        self.send_cmd("PING")

    @Slot()
    def get_status(self):
        """
        Request the current status from the ESP32 device.
        
        Sends "CMD GET_STATUS" to retrieve the device's current operational status.
        """
        self.send_cmd("CMD GET_STATUS")

    @Slot()
    def clear_fault(self):
        """
        Clear any fault condition on the ESP32 device.
        
        Sends "CMD CLEAR_FAULT" to reset fault states and restore normal operation.
        """
        self.send_cmd("CMD CLEAR_FAULT")

    @Slot(bool)
    def estop(self, state: bool):
        """
        Set the emergency stop state.
        
        Args:
            state (bool): True to activate emergency stop, False to release.
                         The command format uses 1 for active, 0 for released.
        """
        self.send_cmd(f"CMD ESTOP state={1 if state else 0}")

    @Slot(str)
    def home(self, axis: str):
        """
        Home a specific axis to its reference position.
        
        Args:
            axis (str): The axis identifier to home (e.g., "X", "Y", "Z").
        """
        self.send_cmd(f"CMD HOME axis={axis}")

    @Slot(str, float, float, float)
    def move_abs(self, axis: str, pos: float, vel: float, accel: float):
        """
        Move an axis to an absolute position with specified velocity and acceleration.
        
        Args:
            axis (str): The axis identifier (e.g., "X", "Y", "Z").
            pos (float): Target absolute position.
            vel (float): Velocity for the movement.
            accel (float): Acceleration for the movement.
        """
        self.send_cmd(
            f"CMD MOVE_ABS axis={axis} pos={pos:.3f} vel={vel:.3f} accel={accel:.3f}"
        )

    @Slot(str, float)
    def move_vel(self, axis: str, vel: float):
        """
        Move an axis at a constant velocity.
        
        Args:
            axis (str): The axis identifier (e.g., "X", "Y", "Z").
            vel (float): Velocity for the movement (can be negative for reverse).
        """
        self.send_cmd(f"CMD MOVE_VEL axis={axis} vel={vel:.3f}")

    @Slot(float)
    def set_heater(self, setpoint: float):
        """
        Set the heater temperature setpoint.
        
        Args:
            setpoint (float): Desired temperature setpoint in degrees.
        """
        self.send_cmd(f"CMD SET_HEATER setpoint={setpoint:.1f}")

    @Slot(int)
    def set_fan(self, pwm: int):
        """
        Set the fan PWM value.
        
        The PWM value is automatically clamped to the valid range [0, 255].
        
        Args:
            pwm (int): PWM value between 0 (off) and 255 (full speed).
        """
        pwm = max(0, min(255, pwm))
        self.send_cmd(f"CMD SET_FAN pwm={pwm}")

    @Slot(str)
    def start_job(self, job_id: str):
        """
        Start a predefined job by its identifier.
        
        Args:
            job_id (str): The unique identifier of the job to start.
        """
        self.send_cmd(f"CMD START_JOB job_id={job_id}")

    @Slot()
    def abort_job(self):
        """
        Abort the currently running job.
        
        Immediately stops execution of any active job and returns to idle state.
        """
        self.send_cmd("CMD ABORT_JOB")

    @Slot(int)
    def start_stream(self, rate_hz: int):
        """
        Start streaming data from the ESP32 at a specified rate.
        
        Args:
            rate_hz (int): Streaming rate in Hertz (updates per second).
        """
        self.send_cmd(f"CMD START_STREAM rate_hz={rate_hz}")

    @Slot()
    def stop_stream(self):
        """
        Stop the current data stream from the ESP32.
        
        Halts any active data streaming and returns to command mode.
        """
        self.send_cmd("CMD STOP_STREAM")

    
    @Slot(bool)
    def set_clamp(self, closed: bool):
        """
        Set the clamp state to open or closed.
        
        Args:
            closed (bool): True to close the clamp, False to open it.
        """
        self.send_cmd(f"CMD SET_CLAMP state={1 if closed else 0}")

    
    @Slot(bool)
    def set_carriage(self, in_water: bool):
        """
        Set the carriage water immersion state.
        
        Args:
            in_water (bool): True to immerse carriage in water, False to remove it.
        """
        self.send_cmd(f"CMD SET_CARRIAGE state={1 if in_water else 0}")

    # Function that preps for the test run by sending all commands at once (set_carriage (FalSE),  home(Z)
    @Slot()
    def prep_test_run(self):
        """
        Prepare the device for a test run by sending necessary setup commands.
        
        This method sends commands to ensure the carriage is out of water
        and homes the Z axis before starting a test run.
        """
        self.set_carriage(in_water=False)
        self.home(axis="Z")

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
