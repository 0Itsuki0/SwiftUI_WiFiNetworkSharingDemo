//
//  NetworkSharingManager.swift
//  AccessorySetupKit+WiFiInfrastructure
//
//  Created by Itsuki on 2025/12/13.
//

import SwiftUI
import WiFiInfrastructure
import AccessorySetupKit

@Observable
class NetworkSharingManager {
    var isAutomaticShareEnabled: Bool {
        return self.authorizationState == .automatic
    }
    
    private var networkSharingController: WINetworkSharingController?
    private var authorizationState: WINetworkSharingController.AuthorizationState = .undetermined
    
    init() { }
    
    func initSharingController(for accessory: ASAccessory) async throws {
        // The accessory needs to be connected and using a secure transport when creating the controller, ie:
        // the accessory must be paired and use Bluetooth Secure Connections, as defined in Bluetooth 4.2 from 2014. This involves a Bluetooth connection using:
        // - Secure Simple Pairing
        // - Encryption of all data with AES-128
        // For information on Bluetooth security modes, see [NIST Special Publication 800-121: Guide to Bluetooth Security](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-121r2-upd1.pdf).
        self.networkSharingController = try await WINetworkSharingController(for: accessory)
    }
    
    func deinitSharingController() {
        self.networkSharingController = nil
    }
    
    // this method does not actually share the network but initiate a share request to be process in the transport extension
    
    func shareNetwork() async throws {
        print(#function)

        guard let networkSharingController = self.networkSharingController else {
            throw WifiNetworkSharingError.sharingControllerNotInitialized
        }

        try await self.checkAuthorization()
        
        // Call this method to prompt your app extension to ask the person to share new networks.
        // Your container app needs to run in the foreground to submit a new sharing request to your app extension using this API.
        let shareState = try await networkSharingController.askToShare()
        if shareState == .denied {
            throw WifiNetworkSharingError.shareDenied
        }
    }
    
    // Requests network-sharing authorization for the specified accessory at initial setup.
    private func checkAuthorization() async throws {
        guard let networkSharingController = self.networkSharingController else {
            throw WifiNetworkSharingError.sharingControllerNotInitialized
        }
        switch self.authorizationState {
        case .denied:
            throw WifiNetworkSharingError.notAuthorized
        case .undetermined:
            self.authorizationState = try await networkSharingController.requestAuthorization()
            return try await self.checkAuthorization()
        case .askToShare:
            return
        case .automatic:
            return
        @unknown default:
            return
        }
    }
}
