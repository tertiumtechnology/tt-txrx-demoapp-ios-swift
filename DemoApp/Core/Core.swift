/*
 * The MIT License
 *
 * Copyright 2017 Tertium Technology.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
import Foundation
import TxRxLib

///
///
/// Core is a singleton proxy class responsible for dispatching notifications received from Tertium TxRx Devices to the whole application
///
/// NOTE:  This class is just a commodity created for persistence in handling TxRxManager and TxRxDevice callbacks. You are free to use a different architecture when building applications with TxRxMananger library
///
/// Implementing TxRxManager library protocols in viewcontrollers is NOT a good architecture choice and may have persistence issues
/// (ViewController being destroyed while still being delegate to either TxRxManager or TxRxManagerDevice callbacks crashing the application)
///
/// Methods are ordered chronologically
class Core: TxRxDeviceScanProtocol, TxRxDeviceDataProtocol {
    // MARK: Core notification name constants
    static let TXRX_NOTIFICATION_NAME = "TxRxNotification"
    static let TXRX_NOTIFICATION_SCAN_BEGAN = "TxRxScanBegan"
    static let TXRX_NOTIFICATION_SCAN_ERROR = "TxRxScanError"
    static let TXRX_NOTIFICATION_SCAN_ENDED = "TxRxScanEnded"
    static let TXRX_NOTIFICATION_DEVICE_ERROR = "TxRxDeviceError"
    static let TXRX_NOTIFICATION_DEVICE_FOUND = "TxRxDeviceFound"
    static let TXRX_NOTIFICATION_DEVICE_CONNECT_ERROR = "TxRxDeviceConnectError"
    static let TXRX_NOTIFICATION_DEVICE_CONNECTED = "TxRxDeviceConnected"
    static let TXRX_NOTIFICATION_DEVICE_READY = "TxRxDeviceReady"
    static let TXRX_NOTIFICATION_DEVICE_DISCONNECTED = "TxRxDeviceDisconnected"
    static let TXRX_NOTIFICATION_DEVICE_DATA_SENT = "TxRxDeviceDataSent"
    static let TXRX_NOTIFICATION_DEVICE_DATA_SEND_ERROR = "TxRxDeviceDataSendError"
    static let TXRX_NOTIFICATION_DEVICE_DATA_SEND_TIMEOUT = "TxRxDeviceDataSendTimeout"
    static let TXRX_NOTIFICATION_DEVICE_DATA_RECEIVED = "TxRxDeviceDataReceived"
    static let TXRX_NOTIFICATION_DEVICE_DATA_RECEIVE_ERROR = "TxRxDeviceDataReceiveError"
    static let TXRX_NOTIFICATION_INTERNAL_ERROR = "TxRxDeviceInternalError"
    
    // MARK: Core properties
    private let _notificationCenter = NotificationCenter.default
    private static let _sharedInstance = Core()
    private var _manager: TxRxManager?
    private var _scannedDevices = [TxRxDevice]()
    
    // MARK: Core class implementation
    class func getCore() -> Core {
        return _sharedInstance;
    }
    
    init() {
        _manager = TxRxManager.getInstance()
        _manager?._delegate = self
    }
    
    func IsScanning() -> Bool {
        return (_manager?._isScanning)!
    }
    
    /// Commences device scan
    func startScan() {
        _manager?.startScan()
    }
    
    /// Gets an array of devices scanned in previous startScan run
    ///
    /// NOTE: Notification delegate will also receive the *single* device found notification for each device
    func getScannedDevices() -> [TxRxDevice] {
        return _scannedDevices;
    }
    
    /// Stops device scanning. You may now connect to devices
    func stopScan() {
        _manager?.stopScan()
    }
    
    /// Tries to connect to a previously found (by startScan) BLE device
    ///
    /// NOTE: Connect is an asyncronous operation, delegate will be informed when and if connected
    ///
    /// NOTE: TxRxManager library will connect ONLY to Tertium BLE devices (service UUID and characteristic UUID will be matched)
    ///
    /// - parameter device: the TxRxDevice device to connect to, MUST be non null
    func connectDevice(device: TxRxDevice) {
        _manager?.connectDevice(device: device)
    }
    
    /// Begins sending the Data byte buffer to a connected device.
    ///
    /// NOTE: you may ONLY send data to already connected devices
    ///
    /// NOTE: Data to device is sent in MTU fragments (refer to TxRxDeviceProfile maxSendPacketSize class attribute)
    ///
    /// - parameter device: the device to send the data (must be connected first!)
    /// - parameter data: Data class with contents of data to send
    func sendData(device: TxRxDevice, data: Data) {
        _manager?.sendData(device: device, data: data)
    }
    
    /// Disconnect a previously connected device
    ///
    /// - parameter device: The device to disconnect, MUST be non null
    func disconnectDevice(device: TxRxDevice) {
        _manager?.disconnectDevice(device: device)
    }
    
    // MARK: TxRxDeviceScanProtocol implementation
    func deviceScanError(error: NSError) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: error, userInfo: ["type": Core.TXRX_NOTIFICATION_SCAN_ERROR])
    }
    
    /// Notifies observers that device scan has began
    func deviceScanBegan() {
        _scannedDevices.removeAll()
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: nil, userInfo: ["type": Core.TXRX_NOTIFICATION_SCAN_BEGAN])
    }
    
    /// Notifies observers that a device has been found
    ///
    /// - parameter device: The device found
    func deviceFound(device: TxRxDevice) {
        _scannedDevices.append(device)
        device.delegate = self
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: device, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_FOUND])
    }
    
    /// Notifies observers that device scan has ended
    func deviceScanEnded() {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: nil, userInfo: ["type": Core.TXRX_NOTIFICATION_SCAN_ENDED])
    }
    
    /// Notifies observers that there has been a critical error
    ///
    /// - parameter error: The error happened
    func deviceInternalError(error: NSError) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: error, userInfo: ["type": Core.TXRX_NOTIFICATION_INTERNAL_ERROR])
    }
    
    // MARK: TxRxDeviceDataProtocol implementation
    
    /// Notifies observers that there has been an error connecting to a device
    ///
    /// - parameter device: The device unable to connect to
    /// - parameter error: The error happened
    func deviceConnectError(device: TxRxDevice, error: NSError) {
        if error.code == TxRxManagerErrors.ErrorCodes.ERROR_DEVICE_DISCONNECT_TIMED_OUT.rawValue {
            deviceDisconnected(device: device)
            return
        }
        
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: error, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_CONNECT_ERROR])
    }
    
    /// Notifies observers that a device has been connected
    ///
    /// NOTE: Now you may interact with the device
    ///
    /// - parameter device: The connected device
    func deviceConnected(device: TxRxDevice) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: device, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_CONNECTED])
    }
    
    /// Notifies observers that there has been an error connecting to a device
    ///
    /// - parameter device: The device unable to connect to
    func deviceReady(device: TxRxDevice) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: device, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_READY])
    }
    
    /// Notifies observers that there has been an error sending data to a device
    ///
    /// - parameter device: The device to which the data wasn't correctly sent
    func deviceWriteError(device: TxRxDevice, error: NSError) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: error, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_DATA_SEND_ERROR])
    }
    
    /// Sends data to a previously connected device
    ///
    /// - parameter device: The device to which to send the Data bytes
    func sentData(device: TxRxDevice) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: device, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_DATA_SENT])
    }
    
    /// Notifies observers that there has been an error receiving data from a device
    ///
    /// - parameter device: The device to which the data cannot be read
    func deviceReadError(device: TxRxDevice, error: NSError) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: error, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_DATA_RECEIVE_ERROR])
    }
    
    /// Notifies observers that there some data arrived from a device
    ///
    /// - parameter device: The device which sent the data
    func receivedData(device: TxRxDevice, data: Data) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: data, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_DATA_RECEIVED])
    }
    
    /// Notifies observers that there has been a critical error on a device
    ///
    /// - parameter device: The device which caused the error
    func deviceError(device: TxRxDevice, error: NSError) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: error, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_ERROR])
    }
    
    /// Notifies observers a device has been correctly disconnected
    ///
    /// - parameter device: The device which was disconnected
    func deviceDisconnected(device: TxRxDevice) {
        _notificationCenter.post(name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: device, userInfo: ["type": Core.TXRX_NOTIFICATION_DEVICE_DISCONNECTED])
    }
}
