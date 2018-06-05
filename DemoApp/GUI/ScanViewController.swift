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
import TxRxLib

class ScanViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var devicesTableView: UITableView!
    var btnScan: UIButton?
    private var defaultColor: UIColor? = nil

    private let core = Core.getCore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveTxRxNotification), name: NSNotification.Name(rawValue: Core.TXRX_NOTIFICATION_NAME), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1;
        } else {
            return core.getScannedDevices().count;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            let cell: BleTableViewHeaderCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") as! BleTableViewHeaderCell
            btnScan = cell.scanButton
            defaultColor = cell.backgroundColor!
            return cell
        } else {
            let cell: BleTableViewDeviceCell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell") as! BleTableViewDeviceCell
            let device: TxRxDevice = core.getScannedDevices()[indexPath.row]
            var deviceName: String
            
            deviceName = device.name
            if (device.isConnected) {
                deviceName = deviceName + " (C)"
                cell.backgroundColor = UIColor.red
            } else {
                cell.backgroundColor = defaultColor
            }
            cell.deviceLabel.text = deviceName
            return cell
        }
    }
    
    @objc func receiveTxRxNotification(_ notification: Notification) {
        let type: String? = notification.userInfo?["type"] as? String
        
        // Handles Core class reflected notifications. The notifications are reflections of TxRxDeviceScanProtocol delegate callbacks
        if (type == Core.TXRX_NOTIFICATION_SCAN_BEGAN) {
            btnScan?.setTitle("STOP", for: .normal)
            devicesTableView.reloadData()
        } else if (type == Core.TXRX_NOTIFICATION_SCAN_ERROR) {
            var error: NSError?
            error = notification.object as? NSError
            
            let alertView = UIAlertView(title: "Error", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
            alertView.show()
        } else if (type == Core.TXRX_NOTIFICATION_SCAN_ENDED) {
            btnScan?.setTitle("SCAN", for: .normal)
        } else if (type == Core.TXRX_NOTIFICATION_DEVICE_FOUND) {
            devicesTableView.reloadData()
        } else if (type == Core.TXRX_NOTIFICATION_DEVICE_CONNECTED) {
            devicesTableView.reloadData()
        } else if (type == Core.TXRX_NOTIFICATION_DEVICE_READY) {
            // Device is ready, we have discovered Tertium characteristics
        } else if (type == Core.TXRX_NOTIFICATION_DEVICE_DISCONNECTED) {
            devicesTableView.reloadData()
        } else if (type == Core.TXRX_NOTIFICATION_INTERNAL_ERROR) {
            var error: NSError?
            error = notification.object as? NSError
            
            if error?.code == TxRxManagerErrors.ErrorCodes.ERROR_BLUETOOTH_NOT_READY_OR_LOST.rawValue {
                let alertView = UIAlertView(title: "Error", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                alertView.show()
            }
        }
    }
    
    func canStartScan() -> Bool {
        let devices: [TxRxDevice] = core.getScannedDevices()
        
        for device: (TxRxDevice) in devices {
            if (device.isConnected) {
                return false;
            }
        }
        
        return true;
    }
    
    @IBAction func btnScanPressed(_ sender: Any) {
        if canStartScan() == false {
            let alertView = UIAlertView(title: "Error", message: "Unable to start scanning with connected devices. Disconnect all devices first!", delegate: nil, cancelButtonTitle: "OK")
            alertView.show()
            return;
        }
        
        if core.IsScanning() == false {
            core.startScan()
        } else {
            core.stopScan()
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailView" {
            if let detail = segue.destination as? DeviceDetailViewController {
                if let row = devicesTableView.indexPathForSelectedRow?.row {
                    detail.device = core.getScannedDevices()[row]
                    if core.IsScanning() {
                        core.stopScan()
                    }
                }
            }
        }
    }
    
    @IBAction func unwindToScanController(for unwindSegue: UIStoryboardSegue, towardsViewController subsequentVC: UIViewController) {
    }
}
