//
//  NetBrowse.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/20/24.
//

import Foundation
import Network
import SwiftUI

struct DiscoveredNooService : Hashable {
    var id : Int
    var name : String = ""
    var host_ip : String = ""
    var port : Int = 50000
}

struct NetBrowseView : View {
    @StateObject var instance = NooServerListener()
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        List(instance.dest, id: \.self) { service in
            HStack {
                Text(service.name)
                Spacer()
                Divider()
                Button("Window") {
                    launch_window(target: service)
                }
                Divider()
                Button("Immersive") {
                    launch_immersive(target: service)
                }
            }
        }
        .onAppear() {
            start_browsing()
        }
    }
    
    func start_browsing() {
        instance.startDiscovery()
    }
    
    func launch_window(target: DiscoveredNooService) {
        let host = "ws://\(target.host_ip):\(target.port)"
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: host))
    }
    
    func launch_immersive(target: DiscoveredNooService) {
        let host = "ws://\(target.host_ip):\(target.port)"
        
        Task {
            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: NewNoodles(hostname: host))
            
            if case .error = result {
                print("An error occurred")
            }
        }
    }
}

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
    
    var services: [Int : NetService]
    var rservices : [NetService : Int]
    
    @Published var dest : [DiscoveredNooService] = []
    var next_service_id = 0

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
        service.delegate = self
        service.resolve(withTimeout: 10)
        
        self.services[self.next_service_id] = service
        self.rservices[service] = self.next_service_id
        self.next_service_id += 1
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print ("Removed: \(service.name)")

        if let id = rservices[service] {
            services.removeValue(forKey: id)
            
            let item = self.dest.firstIndex(where: { desc in desc.id == id } )!
            self.dest.remove(at: item)
        }
        rservices.removeValue(forKey: service)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("service resolved \(sender.name)")
        
        let hname = "\(sender.name) @ \(sender.hostName ?? "Unknown")"
        let host_ip = service_to_ip_string(sender)
        
        self.dest.append(DiscoveredNooService(
            id: rservices[sender]!,
            name: hname,
            host_ip: host_ip,
            port: sender.port
        ))
    }
        
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("service did not resolve \(sender.name)")
    }
}
