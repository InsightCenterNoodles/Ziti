//
//  ARKitManager.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 4/9/25.
//

import ARKit

@Observable
@MainActor
class ARKitManager {
    static let shared = ARKitManager()
    
    let session = ARKitSession()
    let sceneReconstruction = SceneReconstructionProvider()
    
    var is_started = false
    
    /// Provider of tracked images
    let image_info = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "TrackingImages")
    )
    
    let hand_tracking = HandTrackingProvider()
    
    func start() {
        guard is_started == false else { return }
        
        var providers : [any DataProvider] = []
        
        if SceneReconstructionProvider.isSupported {
            print("Reconstruction supported")
            
            if sceneReconstruction.state == .initialized {
                print("Reconstruction able to start")
                
                providers.append(sceneReconstruction)
                
            }
        }
        
        if ImageTrackingProvider.isSupported {
            print("Image tracking supported")
            providers.append(image_info)
        }
        
        if HandTrackingProvider.isSupported {
            print("Hand tracking supported")
            providers.append(hand_tracking)
        }
        
        is_started = true
        
        Task { @MainActor in
            try await session.run(providers)
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(type: _, status: let status):
                print("Authorization status changed: \(status)")
                
                if status == .denied {
                    // error?
                }
            case .dataProviderStateChanged(dataProviders: let provider, newState: let newState, error: let err):
                print("Data provider changed state: \(provider), \(newState)")
                if let err = err {
                    print("Associated error \(err)")
                }
            @unknown default:
                print("Unknown event \(event)")
            }
        }
    }
}
