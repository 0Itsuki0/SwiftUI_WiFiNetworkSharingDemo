//
//  TransportExtension.swift
//  TransportExtension
//
//  Created by Itsuki on 2025/12/13.
//

import AccessorySetupKit
import AccessoryTransportExtension
import ExtensionFoundation
import Foundation
import os.log

let subsystem = "com.example.accessory-transport-extension"
private let logger = Logger(subsystem: subsystem, category: "Extension")

/// Main entry point for the Accessory Transport Extension.
///
/// This extension handles incoming session requests for a single `ASAccessory`.
/// The `ASAccessory` associated with this session can be obtained from activating
/// an `ASAccessorySession` object, and accessing the first element in `[accessories]`.
///
/// Accepting the `AccessoryTransportSession.Request` with an `EventHandler` is
/// required. Alternatively, the session can be rejected.
///
/// See `WiFiNetworkSharingProvider` for an example on how to get data from system frameworks.
///
/// - Note: There is no wireless protocol defined.
@available(iOS 26.2, *)
@main
struct TransportExtension: AccessoryTransportAppExtension {

    /// Bind to the extension point.
    @AppExtensionPoint.Bind
    static var boundExtensionPoint: AppExtensionPoint {
        AppExtensionPoint.Identifier("com.apple.accessory-transport-extension")
    }

    /// Accepts an incoming session request for an accessory.
    ///
    /// An `EventHandler` must be provided when accepting a new session.
    ///
    /// - Parameter sessionRequest: The incoming session request.
    /// - Returns: A decision to accept (with handler) or reject the session request.
    func accept(sessionRequest: AccessoryTransportSession.Request) -> AccessoryTransportSession.Request.Decision {
        logger.info("Receive session request")
        return sessionRequest.accept {
            return EventHandler(session: sessionRequest.session)
        }
    }

    // MARK: -

    /// Handles session lifecycle events.
    class EventHandler: AccessoryTransportSession.EventHandler {
        private var accessorySession = ASAccessorySession()
        private var sharingProvider: WiFiNetworkSharingProvider?
        private var transportSession: AccessoryTransportSession

        // MARK: -

        /// Initializes the event handler with a transport session.
        ///
        /// - Parameter session: The transport session for the accessory.
        init(session: AccessoryTransportSession) {
            transportSession = session
            accessorySession.activate(on: DispatchQueue.main, eventHandler: handleASAccessoryEvent(event:))
        }

        /// Handles session invalidation and cleanup.
        ///
        /// Called by session host on the provided (accepted) `EventHandler`.
        func invalidationHandler(error: AccessoryTransportSession.Error?) {
            accessorySession.invalidate()
            sharingProvider?.invalidate()
        }

        // MARK: -

        /// Handles `ASAccessorySession` events.
        ///
        /// This method responds to accessory lifecycle events, particularly the activation event
        /// which triggers initialization and configuration of the `WiFiNetworkSharingProvider`.
        ///
        /// - Parameter event: The accessory event to process.
        private func handleASAccessoryEvent(event: ASAccessoryEvent) {
            switch event.eventType {
            case .activated:
                guard let accessory = accessorySession.accessories.first(where: {$0.descriptor.bluetoothServiceUUID == CounterAccessory.serviceUUID}) else { return }

                /// `WiFiNetworkSharingProvider` should be initialized when the extension
                /// has established connection to the accessory, and is ready to start transmitting data.
                sharingProvider = WiFiNetworkSharingProvider(for: accessory)
                sharingProvider?.activate()
            case .invalidated:
                sharingProvider?.invalidate()
            default:
                break
            }
        }
    }
}
