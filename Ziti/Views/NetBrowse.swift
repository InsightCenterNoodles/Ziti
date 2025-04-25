//
//  NetBrowse.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/20/24.
//

import Foundation
import Network
import SwiftUI

/// Hacked together from github sources. Attempt to obtain an IP from a network service
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
