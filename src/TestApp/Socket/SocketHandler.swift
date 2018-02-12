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

class SocketHandler: NSObject, GCDAsyncSocketDelegate {
    private static var _socketHandler = SocketHandler()
    var _listenSocket: GCDAsyncSocket?
    private var _connectedSocket: GCDAsyncSocket?
    private var _commandTerminator: String = ""
    var _socketBuffer = Data()
    var _socketError: Error?
    var _readDataTimer: Timer?
    var _socketTag: Int = 0
    var _delegate: SocketDataProtocol?
    
    class func getSocketHandler() -> SocketHandler {
        return _socketHandler
    }
    
    func openListenSocket(terminator: String) {
        closeListenSocket()
        _commandTerminator = terminator
        _listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        if let listenSocket = _listenSocket {
            try? listenSocket.accept(onPort: 2001)
        }
    }
    
    func closeListenSocket() {
        _listenSocket?.disconnect()
        _connectedSocket?.disconnect()
        _listenSocket = GCDAsyncSocket()
        _connectedSocket = nil
    }
    
    func sendData(data: Data) {
        if (_connectedSocket != nil) {
            _connectedSocket?.write(data, withTimeout: 1, tag: _socketTag)
            _socketTag += 1
        }
    }
    
    @objc func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        return 1.0;
    }
    
    @objc func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        _connectedSocket = newSocket
        _connectedSocket?.readData(withTimeout: 1, tag: _socketTag)
        _socketTag += 1
    }
	
    @objc func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        var text: String
        var commands: [String]
        var sentLen: Int = 0
        
        _socketBuffer.append(data)
        text = String(data: _socketBuffer, encoding: String.Encoding.ascii) ?? ""
        commands = text.components(separatedBy: _commandTerminator)
        if commands.count != 0 && _delegate != nil {
            for command: String in commands {
                if (command.count >= _commandTerminator.count && command != text) {
                    var newCmd: String
                    newCmd = String() + command + _commandTerminator
                    sentLen += _commandTerminator.count + command.count
                    _delegate?.receivedCommand(command: newCmd)
                }
            }
            
            if sentLen != 0 {
                var newData = Data()
                
                newData.append(_socketBuffer.subdata(in: sentLen..<_socketBuffer.count))
                _socketBuffer = newData
            }
        }
        
        _connectedSocket?.readData(withTimeout: 1, tag: _socketTag)
        _socketTag += 1    }
    }
