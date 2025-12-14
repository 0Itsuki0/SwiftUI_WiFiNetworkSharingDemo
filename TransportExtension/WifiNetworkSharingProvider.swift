//
//  WifiNetworkSharingProvider.swift
//  TransportExtension
//
//  Created by Itsuki on 2025/12/13.
//

import AccessorySetupKit.ASAccessory
import AccessoryTransportExtension
import Foundation
import Network
import os.log
import WiFiInfrastructure
import CoreBluetooth

fileprivate let logger = Logger(subsystem: subsystem, category: "WiFiNetworkSharingProvider")

// Responsible for managing WiFi network sharing operations and events.
//
// `WiFiNetworkSharingProvider` fetches Wi-Fi networks
// via `WINetworkSharingProvider`, which requires an `ASAccessory` parameter.
@available(iOS 26.2, *)
final class WiFiNetworkSharingProvider: @unchecked Sendable {

    // The accessory associated with this extension session.
    private let accessory: ASAccessory

    // Task for managing network event listening.
    private var networkEventTask: Task<Void, Never>?
    
    private var bluetoothManager = BluetoothCentralManager()
    
    private var sharingProvider: WINetworkSharingProvider?

    init(for accessory: ASAccessory) {
        self.accessory = accessory
        self.bluetoothManager.initCBCentralManager(for: accessory, onReceiveNetworkRequest: nil)
    }

    // Activates the sharing provider.
    //
    // This method should be called after initialization, and
    // when accessory is ready to receive network events.
    func activate() {
        guard networkEventTask == nil else { return }
        logger.info("Activate \(self.accessory.bluetoothIdentifier?.uuidString ?? "")")

        networkEventTask = Task {
            await listenForNetworkEvents()
        }
    }


    // Invalidates the sharing provider and releases all associated resources.
    //
    // This method cleans up all references and should be
    // called when the session is no longer needed.
    func invalidate() {
        guard networkEventTask != nil else { return }
        networkEventTask?.cancel()
        networkEventTask = nil

        logger.info("Invalidated")
    }

    // Monitors Wi-Fi network events and handles user consent flow for network sharing.
    private func listenForNetworkEvents() async {
        do {
            let sharingProvider = try await WINetworkSharingProvider(for: accessory)
            self.sharingProvider = sharingProvider
            
            try await retrievePeripheralAndConnect()
            logger.info("Peripheral connected")
            
            for try await event in sharingProvider.networkEvents() {
                guard !Task.isCancelled else { break }
                do {
                    try await handleNetworkEvent(event)
                } catch(let error)  {
                    logger.error("Failed to handleNetworkEvent: \(error)")
                }
            }
            
        } catch(let error) {
            logger.error("Failed to get network events: \(error)")
        }
    }
    
    
    func retrievePeripheralAndConnect() async throws {
        try await waitForBluetoothPowerOn()
        try self.bluetoothManager.retrieveCounterPeripheral()
        try self.bluetoothManager.connectCounterPeripheral()
        try await waitForFinishDiscoveringCharacteristic()
    }
    
    private func waitForBluetoothPowerOn() async throws {
        try await self.waitFor({
            return self.bluetoothManager.bluetoothState == .poweredOn
        }, throw: BluetoothCentralManager.BluetoothCentralError.bluetoothNotAvailable)
    }
    
    private func waitForFinishDiscoveringCharacteristic() async throws {
        try await self.waitFor({
            return self.bluetoothManager.finishDiscoveringCharacteristic
        }, throw: BluetoothCentralManager.BluetoothCentralError.networkCharacteristicNotDiscovered)
    }
    
    private func waitFor(_ condition: () -> Bool, throw error: Error) async throws {
        // 5 seconds
        let maxWaitMillisecond: Double = 10 * 1000
        var currentWait: Double = 0
        let interval: Double = 50
        
        while condition() == false {
            if currentWait > maxWaitMillisecond {
                throw error
            }
            try? await Task.sleep(for: .milliseconds(interval))
            currentWait += interval
            if condition() {
                break
            }
        }
    }

    
    // Handles individual network events.
    private func handleNetworkEvent(_ event: WINetworkSharingProvider.NetworkEvent) async throws {
        
        logger.info("Event received: \(event.description)")
        
        // - appRequestedSharing: The system sets this flag when your container app calls askToShare().
        // - newShareableNetworkAvailable: When user choose to automatically share networks to your accessory, the system automatically provides the network in the networks property without setting this flag, because your app extension doesn’t need to take action.
        //
        // for network requests from accessory:
        // Our accessory can communicate directly with your extension to request network sharing, such as when connection problems occur.
        //
        // However, we will not be handling those network request directly within our extension,
        // ie: implement BluetoothCentralManager.onReceiveNetworkRequest,
        // but have our main app send request for three reasons.
        //
        // 1. We might receive request without ask the authorization yet
        // 2. Our main app needs to be in the foreground in order to be able to present the UI
        // 3. call presentAskToShareUI here without main app request for it is not really reliable
        //
        // If we want the accessory to provide the scanProvider for presentAskToShareUI using the characteristic value, all we have to do is to read that value from the characteristic within the extension directly after getting the request from the container app, either using CBPeripheral.readValue(for:) or if it is notifying, directly using the CBCharacteristic.value property
        if event.appRequestedSharing || event.newShareableNetworkAvailable {
            try await self.presentAskToShareUI()
        }

        try self.bluetoothManager.shareNetworkInfo(event.networks)
    }

    
    private func presentAskToShareUI() async throws {
        guard let sharingProvider = self.sharingProvider else { return }
        let result = try await sharingProvider.presentAskToShareUI(scanProvider: nil)
        if result != .approved {
            throw WifiNetworkSharingError.shareDenied
        }
    }
}
