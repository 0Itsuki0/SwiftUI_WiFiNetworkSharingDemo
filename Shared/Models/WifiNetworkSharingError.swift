//
//  WifiNetworkSharingError.swift
//  WiFiNetworkSharingDemo
//
//  Created by Itsuki on 2025/12/13.
//

import Foundation

enum WifiNetworkSharingError: Error, LocalizedError {
    case sharingControllerNotInitialized
    case notAuthorized
    case shareDenied
    
    var errorDescription: String? {
        switch self {
            
        case .sharingControllerNotInitialized:
            "Sharing Controller Not Initialized"
        case .notAuthorized:
            "App is not authorized to use the shared networks API for the accessory"
        case .shareDenied:
            "User denies to share the network."
        }
    }
}
