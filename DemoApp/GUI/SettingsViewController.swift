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

class SettingsViewController: UIViewController {
    @IBOutlet weak var txtConnectTimeout: UITextField!
    @IBOutlet weak var txtWriteTimeout: UITextField!
    @IBOutlet weak var txtFirstReadTimeout: UITextField!
    @IBOutlet weak var txtLaterReadTimeout: UITextField!
    private let _manager = TxRxDeviceManager.getInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        txtConnectTimeout.text = String(format: "%u", _manager.getTimeOutValue(timeOutType: TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_CONNECT))
        txtWriteTimeout.text = String(format: "%u", _manager.getTimeOutValue(timeOutType: TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_SEND_PACKET))
        txtFirstReadTimeout.text = String(format: "%u", _manager.getTimeOutValue(timeOutType: TxRxDeviceManagerTimeouts.S_TERITUM_TIMEOUT_RECEIVE_FIRST_PACKET))
        txtLaterReadTimeout.text = String(format: "%u", _manager.getTimeOutValue(timeOutType: TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_RECEIVE_PACKETS))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        _manager.setTimeOutValue(timeOutValue: UInt32(txtConnectTimeout.text!)!, timeOutType: TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_CONNECT)
        _manager.setTimeOutValue(timeOutValue: UInt32(txtWriteTimeout.text!)!, timeOutType: TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_SEND_PACKET)
        _manager.setTimeOutValue(timeOutValue: UInt32(txtFirstReadTimeout.text!)!, timeOutType: TxRxDeviceManagerTimeouts.S_TERITUM_TIMEOUT_RECEIVE_FIRST_PACKET)
        _manager.setTimeOutValue(timeOutValue: UInt32(txtLaterReadTimeout.text!)!, timeOutType: TxRxDeviceManagerTimeouts.S_TERTIUM_TIMEOUT_RECEIVE_PACKETS)
    }
}
