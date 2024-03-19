//
//  Communication.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/13/24.
//

import Foundation
import SwiftUI
import SwiftCBOR
import RealityKit
import RealityKitContent
import Starscream


class NoodlesCommunicator {
    var url: URL
    var socket : WebSocket!
    var queue = DispatchQueue(label: "gov.nrel.noodles.ziti")
    var scene : RealityViewContent!
    var decoder : MessageDecoder
    var world : NoodlesWorld!
    
    init(url: URL, scene: RealityViewContent, doc_method_list: MethodListObservable) {
        print("Starting connection to \(url.host() ?? "UNKNOWN")")
        self.url = url
        decoder = MessageDecoder(current_host: url.host()!)
        self.scene = scene
        world = NoodlesWorld(scene, doc_method_list)
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.callbackQueue = queue
        socket.onEvent = self.on_recv_cb
        socket.connect()
    }
    
    public func send<T : NoodlesMessage>(msg: T) {
        let content = msg.to_cbor()
        let packet = CBOR.array([CBOR.unsignedInt(UInt64(T.message_id)), content]).encode()
        socket.write(data: Data(packet))
    }
    
    func on_message(msg: Result<URLSessionWebSocketTask.Message, Error>) {
        switch msg {
        case .success(let m):
            switch m {
            case .data(let d):
                on_message_data(data: d)
            case .string(let s):
                print("Recv text from server: \(s)")
            default:
                break
            }
            break
        case .failure(let err):
            handle_ws_error(err)
        }
    }
    
    func on_message_data(data: Data) {
        let slice = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            //let buffer = UnsafeBufferPointer(start: ptr, count: data.count)
            return ArraySlice(ptr)
        }
        let messages = decoder.decode(bytes: slice)
        DispatchQueue.main.async {
            self.handle_messages(mlist: messages)
        }
        
    }
    
    func handle_ws_error(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
    func on_recv_cb(event: Starscream.WebSocketEvent) {
        switch event {
        case .connected(let headers):
            //isConnected = true
            print("websocket is connected: \(headers)")
            self.send(msg: IntroductionMessage(client_name: "Swift Client"))
        case .disconnected(let reason, let code):
            //isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
            print("Received data: \(data.count)")
            on_message_data(data: data)
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            //isConnected = false
            break;
        case .error(let error):
            //isConnected = false
            handle_ws_error(error)
        case .peerClosed:
           break
        }
    }
    
    func handle_messages(mlist : [FromServerMessage]) {
        // should be in the main thread at this point
        for m in mlist {
            dump(m)
            world.handle_message(m)
        }
    }
}
