//
//  AccessoryManager.swift
//  AccessorySetupKit+WiFiInfrastructure
//
//  Created by Itsuki on 2025/12/12.
//

import SwiftUI
import AccessorySetupKit
import CoreBluetooth

@Observable
class AccessoryManager {
    
    var isAutomaticShareEnabled: Bool {
        return self.networkSharingManager.isAutomaticShareEnabled
    }
    
    var counterPaired: Bool {
        return self.accessorySessionManager.counterPaired
    }
    
    var counterPeripheralConnected: Bool {
        return self.counterPeripheralState == .connected
    }
    
    var counterPeripheralState: CBPeripheralState {
        return self.bluetoothManager.counterPeripheralState
    }
    
    var counterCharacteristicFound: Bool {
        return self.bluetoothManager.counterCharacteristicFound
    }
    
    var count: Int {
        return self.bluetoothManager.count
    }
    
    var bluetoothState: CBManagerState {
        return self.bluetoothManager.bluetoothState
    }
    
    private(set) var error: Error? {
        didSet {
            if let error {
                print(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    self.error = nil
                })
            }
        }
    }
            
    private var accessorySessionManager = AccessorySessionManager()
            
    @ObservationIgnored
    private var accessoryErrorTask: Task<Void, Error>?
    
    private var bluetoothManager = BluetoothCentralManager()
    
    @ObservationIgnored
    private var bluetoothErrorTask: Task<Void, Error>?
    
    private var networkSharingManager = NetworkSharingManager()


    init() {
        
        self.accessorySessionManager.handleAccessoryAdded = {
            guard let counterAccessory = self.accessorySessionManager.counterAccessory else {
                return
            }
            
            // Initialize CBCentralManager after accessory added.
            //
            // In the case of migrating an accessory,
            // if we  initialize a CBCentralManager before migration is complete,
            // we will receives an error event and the picker fails to appear.
            self.bluetoothManager.initCBCentralManager(for: counterAccessory, onReceiveNetworkRequest: {
                self.shareNetwork({ error in
                    try? self.bluetoothManager.sendNetworkRequestResult(error)
                })
            })
            
            Task {
                do {
                    try await self.networkSharingManager.initSharingController(for: counterAccessory)
                } catch(let error) {
                    self.error = error
                }
            }
            
        }
        
        self.accessorySessionManager.handleAccessoryRemoved = {
            if self.counterPeripheralConnected == true {
                self.disconnectCounter()
            }
            self.bluetoothManager.deinitCBCentralManager()
            self.networkSharingManager.deinitSharingController()
        }
        
        self.accessoryErrorTask = Task {
            for await error in self.accessorySessionManager.errorsStream {
                self.error = error
            }
        }
        
        self.bluetoothErrorTask = Task {
            for await error in self.bluetoothManager.errorsStream {
                self.error = error
            }
        }
    }
    
    
    func presentAccessoryPicker() async {
        do {
            try await self.accessorySessionManager.presentAccessoryPicker()
        } catch(let error) {
            self.error = error
        }
    }

    
    func connectCounter() {
        do {
            try self.bluetoothManager.retrieveCounterPeripheral()
            try self.bluetoothManager.connectCounterPeripheral()
        } catch (let error) {
            self.error = error
        }
    }
    
    func discoverCounterCharacteristic() {
        do {
            try self.bluetoothManager.discoverCounterCharacteristics()
        } catch (let error) {
            self.error = error
        }
    }
    
    // need to be called after connected to the peripheral (counter in this case)
    func shareNetwork(_ onError: ((Error) -> Void)? = nil) {
        guard self.bluetoothManager.counterPeripheralState == .connected else { return }
        
        Task {
            do {
                try await self.networkSharingManager.shareNetwork()
            } catch(let error) {
                self.error = error
                onError?(error)
            }
        }
    }
    
    
    func setCount(_ count: Int) {
        do {
            try self.bluetoothManager.setCount(count)
        } catch(let error) {
            self.error = error
        }
    }

    func disconnectCounter() {
        self.bluetoothManager.disconnectCounterPeripheral()
    }
    
    
    func removeCounter() async  {
        if self.counterPeripheralConnected == true {
            self.disconnectCounter()
        }

        do {
            try await self.accessorySessionManager.removeCounter()
        } catch (let error) {
            self.error = error
        }
        
        self.bluetoothManager.deinitCBCentralManager()
    }

}
