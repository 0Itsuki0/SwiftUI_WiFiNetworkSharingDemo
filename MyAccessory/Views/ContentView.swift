//
//  ContentView.swift
//  MyAccessory
//
//  Created by Itsuki on 2025/12/10.
//

import SwiftUI
import WiFiInfrastructure

struct ContentView: View {
    @Environment(BluetoothPeripheralManager.self) private var peripheralManager
    
    @State private var showNetworkSheet: Bool = false
    
    var body: some View {
        
        @Bindable var peripheralManager = peripheralManager
        
        NavigationStack {
            VStack(spacing: 48) {
                CounterView(count: $peripheralManager.count)
                                
                VStack(spacing: 16) {
                    Toggle("Advertise", isOn: $peripheralManager.isAdvertising)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Connected Centrals")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(self.peripheralManager.subscribedCentralCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    if let error = peripheralManager.error {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        
                    } else {
                        Text(" ")
                    }
                    
                }
                .padding(.horizontal, 24)
                
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.1))
            .navigationTitle("BLE Accessory")
            .toolbar(content: {
                Button(action: {
                    self.showNetworkSheet = true
                }, label: {
                    Image(systemName: "network")
                })
                .buttonBorderShape(.circle)
                .buttonStyle(.glassProminent)
            })
            .sheet(isPresented: $showNetworkSheet, content: {
                NetworkManagementSheet()
                    .environment(self.peripheralManager)
            })
        }
    }
}

struct NetworkManagementSheet: View {
    @Environment(BluetoothPeripheralManager.self) private var peripheralManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let error = peripheralManager.error {
                        Text(String("\(error)"))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.leading)
                    }
                }
                Section("Networks shared with me") {
                    if self.peripheralManager.networks.isEmpty {
                        Text("No network received.")
                            .foregroundStyle(.secondary)
                    }
            
                    ForEach(self.peripheralManager.networks) { network in
                        NetworkView(network: network)
                    }
                }
                
                Section {
                    Button(action: {
                        self.peripheralManager.isRequestingNetwork = true
                    }, label: {
                        Text("Request For Networks")
                            .font(.headline)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                    })
                    .buttonStyle(.glassProminent)
                    .disabled(self.peripheralManager.subscribedCentralCount <= 0 || self.peripheralManager.isRequestingNetwork)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.all, 0)

                }
                .listSectionMargins(.vertical, 0)
            }
            .navigationTitle("Networks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button(action: {
                        self.dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    .buttonBorderShape(.circle)
                    .buttonStyle(.glassProminent)
                })
            
            })
        }
    }
}


struct NetworkView: View {
    var network: WINetworkSharingProvider.Network
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(network.ssid.stringRepresentation ?? network.ssid.description)
                .lineLimit(1)
                .font(.headline)
            
            VStack (alignment: .leading, spacing: 8) {
                
                let securityPolicy = network.securityPolicy.map(\.stringRepresentation).joined(separator: ", ")
                Text("Security Policies: \(network.securityPolicy.isEmpty ? "No policy specified" : securityPolicy)")
                
                Text("Credentials: \(network.credentials.stringRepresentation)")

            }
            .font(.caption)
            .foregroundStyle(.secondary)

        }
    }
}



#Preview {
    ContentView()
        .environment(BluetoothPeripheralManager())
}
