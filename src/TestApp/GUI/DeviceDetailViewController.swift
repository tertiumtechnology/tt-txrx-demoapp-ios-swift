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
import UIKit

class DeviceDetailViewController: UIViewController, SocketDataProtocol {
    @IBOutlet weak var lblDevice: UILabel!
    @IBOutlet weak var btnWrite: UIButton!
    @IBOutlet weak var btnConnect: UIButton!

    @IBOutlet weak var txtReceive: UITextView!
    @IBOutlet weak var txtDataToSend: UITextField!
    private let core = Core.getCore()
    private let _socketHandler = SocketHandler.getSocketHandler()
    private var font: UIFont?
    var device: TxRxDevice?
    var screenBuffer = NSMutableAttributedString()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        _socketHandler._delegate = self
        
        //
        font = UIFont(name: "Terminal", size: 10.0)
        
        // Add ourself to notification center
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveTxRxNotification), name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: nil)
        
        if device?.isConnected == true {
            btnConnect.setTitle("DISCONNECT", for: .normal)
            appendStatusText("Connected!")
            OpenCommandSocket()
        } else {
            btnConnect.setTitle("CONNECT", for: .normal)
        }
        
        lblDevice.text = device?.name
        txtDataToSend.text = "$:06000E"
        txtReceive.textContainer.lineBreakMode = .byCharWrapping
    }

    deinit {
        _socketHandler.closeListenSocket()
        
        // Remove ourselves from notification center
        NotificationCenter.default.removeObserver(self)
    }
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnConnectPressed(_ sender: Any) {
        if let device = device {
            if device.isConnected == false {
                appendStatusText("Trying to connect...")
                core.connectDevice(device: device)
            } else {
                appendStatusText("Trying to disconnect...")
                core.disconnectDevice(device: device)
            }
        }
        
        view.endEditing(true)
    }
    
    @IBAction func btnWritePressed(_ sender: Any) {
        if let text = txtDataToSend.text {
            if let device = device {
                appendSendText(text)
                core.sendData(device: device, data: text.data(using: String.Encoding.ascii)!)
            }
        }
        
        view.endEditing(true)
    }
    
    func appendData(data: Data) {
        screenBuffer.append(NSAttributedString(string: (String(data: data, encoding: String.Encoding.ascii)!), attributes: [NSAttributedStringKey.foregroundColor: UIColor.yellow]))
        txtReceive.attributedText = screenBuffer.copy() as! NSAttributedString
        scrollDown()
    }
    
    func appendStatusTextWithNoTerminator(_ text: String) {
        screenBuffer.append(NSAttributedString(string: text, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white]))
        txtReceive.attributedText = screenBuffer.copy() as! NSAttributedString
        scrollDown()
    }
    
    func appendStatusText(_ text: String) {
        appendStatusTextWithNoTerminator(text + "\r\n")
        scrollDown()
    }
    
    func appendSendText(_ text: String) {
        screenBuffer.append(NSAttributedString(string: text + "\r\n", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white]))
        txtReceive.attributedText = screenBuffer.copy() as! NSAttributedString
        scrollDown()
    }
    
    func appendSocketText(_ text: String) {
        screenBuffer.append(NSAttributedString(string: text, attributes: [NSAttributedStringKey.foregroundColor: UIColor.green]))
        txtReceive.attributedText = screenBuffer.copy() as! NSAttributedString
        scrollDown()
    }
    
    func appendErrorText(_ text: String) {
        screenBuffer.append(NSAttributedString(string: text + "\r\n", attributes: [NSAttributedStringKey.foregroundColor: UIColor.red]))
        txtReceive.attributedText = screenBuffer.copy() as! NSAttributedString
        scrollDown()
    }
    
    // SocketDataProtocol
    func receivedCommand(command: String) {
        var data: Data?
        if let device = device {
            data = command.data(using: String.Encoding.ascii)
            if let data = data {
                appendSocketText(command)
                core.sendData(device: device, data: data)
            } else {
                appendErrorText("Received data unconvertible to Ascii from socket, unable to send command!")
            }
        }
    }
    
    func scrollDown() {
        let range = NSRange(location: txtReceive.text.count - 1, length: 0)
        txtReceive.scrollRangeToVisible(range)
    }
    
    @objc func receiveTxRxNotification(_ notification: Notification) {
        if let type = notification.userInfo?["type"] as? String {
            // Handles Core class reflected notifications. The notifications are reflections of TxRxDeviceDataProtocol delegate callbacks
            switch type {
                case Core.TXRX_NOTIFICATION_DEVICE_CONNECTED:
                    btnConnect.setTitle("DISCONNECT", for: .normal)
                    appendStatusText("Connected!")
                
                case Core.TXRX_NOTIFICATION_DEVICE_READY:
                    appendStatusText("Tertium characteristics discovered. Device is ready.")
                    OpenCommandSocket()
                
                case Core.TXRX_NOTIFICATION_DEVICE_DATA_RECEIVED:
                    if let data = notification.object as? Data {
                        appendData(data: data)
                        _socketHandler.sendData(data: data)
                    }
                
                case Core.TXRX_NOTIFICATION_DEVICE_DISCONNECTED:
                    btnConnect.setTitle("CONNECT", for: .normal)
                    appendStatusText("Disconnected!")
                    _socketHandler.closeListenSocket()

                case Core.TXRX_NOTIFICATION_DEVICE_ERROR, Core.TXRX_NOTIFICATION_DEVICE_CONNECT_ERROR, Core.TXRX_NOTIFICATION_DEVICE_DATA_RECEIVE_ERROR, Core.TXRX_NOTIFICATION_DEVICE_DATA_SEND_ERROR, Core.TXRX_NOTIFICATION_INTERNAL_ERROR:
                    if let error = notification.object as? Error {
                        appendErrorText(error.localizedDescription)
                    }
                
                default:
                    break
            }
        }
    }
    
    func getIPAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    func OpenCommandSocket() {
        if let deviceProfile = device?.deviceProfile {
            if let ip = getIPAddress() {
                appendStatusTextWithNoTerminator("TCP/IP Server open at ")
                appendStatusTextWithNoTerminator(ip)
                appendStatusText(" port 2001")
                _socketHandler.openListenSocket(terminator: deviceProfile.commandEnd)
            } else {
                appendErrorText("Unable to open commands socket. No IP was found on WiFi interface. Interface down ?")
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func unwind(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
        _socketHandler.closeListenSocket()
    }    
}
