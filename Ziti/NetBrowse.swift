//
//  NetBrowse.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/20/24.
//

import Foundation
import Network
import SwiftUI
//
//struct DiscoveredNooService : Hashable {
//    var id : Int
//    var name : String = ""
//    var host_ip : String = ""
//    var port : Int = 50000
//}
//
//struct NetBrowseView : View {
//    @StateObject var instance = NooServerListener()
//    
//    @Environment(\.openWindow) private var openWindow
//    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
//    @Environment(\.dismissWindow) private var dismissWindow
//    
//    var body: some View {
//        List(instance.dest, id: \.self) { service in
//            HStack {
//                Text(service.name)
//                Spacer()
//                Divider()
//                Menu() {
//                    Button() {
//                        launch_small_window(target: service)
//                    } label: {
//                        Label("Small Space", systemImage: "widget.small")
//                    }
//                    Button() {
//                        launch_window(target: service)
//                    } label: {
//                        Label("Large Space", systemImage: "widget.extralarge")
//                    }
//                    Divider()
//                    Button() {
//                        launch_immersive(target: service)
//                    } label: {
//                        Label("Immersive", systemImage: "sharedwithyou.circle.fill")
//                    }
//                } label: {
//                    Label(service.name, systemImage: "plus").labelStyle(.iconOnly)
//                }.menuStyle(.borderlessButton)
//            }
//            
//        }
//        .onAppear() {
//            start_browsing()
//        }
//    }
//    
//    func start_browsing() {
//        instance.startDiscovery()
//    }
//    
//    func launch_small_window(target: DiscoveredNooService) {
//        print("Launching window")
//        let host = "ws://\(target.host_ip):\(target.port)"
//        openWindow(id: "noodles_content_window_small", value: NewNoodles(hostname: host))
//        dismissWindow(id: "noodles_browser")
//    }
//    
//    func launch_window(target: DiscoveredNooService) {
//        print("Launching window")
//        let host = "ws://\(target.host_ip):\(target.port)"
//        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: host))
//        dismissWindow(id: "noodles_browser")
//    }
//    
//    func launch_immersive(target: DiscoveredNooService) {
//        print("Launching immersive window")
//        let host = "ws://\(target.host_ip):\(target.port)"
//        
//        Task {
//            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: NewNoodles(hostname: host))
//            
//            if case .error = result {
//                print("An error occurred")
//            }
//        }
//        
//        dismissWindow(id: "noodles_browser")
//    }
//}

// stolen from github
func service_to_ip_string(_ sender: NetService) -> String {
    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    guard let data = sender.addresses?.first else { return "" }
    data.withUnsafeBytes { ptr in
        guard let sockaddr_ptr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else {
            // handle error
            return
        }
        let sockaddr = sockaddr_ptr.pointee
        guard getnameinfo(sockaddr_ptr, socklen_t(sockaddr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
            return
        }
    }
    return String(cString:hostname)
}

class NooServerListener: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, ObservableObject  {
    var browser: NetServiceBrowser
    var is_active = false
    
    var services: [UUID : NetService]
    var rservices : [NetService : UUID]
    
    @Published var dest : [Server] = []

    override init() {
        browser = NetServiceBrowser()
        services = [:]
        rservices = [:]
    }

    func startDiscovery() {
        if !is_active {
            browser.delegate = self
            browser.searchForServices(ofType: "_noodles._tcp.", inDomain: "")
            is_active = true
        }
    }

    func stopDiscovery() {
        browser.stop()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print ("Found: \(service.name), resolving")
        
        let id = UUID();
        self.services[id] = service
        self.rservices[service] = id
        
        service.delegate = self
        service.resolve(withTimeout: 10)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print ("Removed: \(service.name)")

        if let id = rservices[service] {
            services.removeValue(forKey: id)
            
            if let item = self.dest.firstIndex(where: { desc in desc.id == id } ) {
                self.dest.remove(at: item)
            }
            
        }
        rservices.removeValue(forKey: service)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("service resolved \(sender.name)")
        
        let hname = "\(sender.name) @ \(sender.hostName ?? "Unknown")"
        let host_ip = service_to_ip_string(sender) + ":\(sender.port)"
        
        self.dest.append(Server(
            id: rservices[sender]!,
            name: hname,
            ipAddress: host_ip,
            discovered: true
        ))
    }
        
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("service did not resolve \(sender.name)")
    }
}
