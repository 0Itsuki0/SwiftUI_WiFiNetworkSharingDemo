//
//  NetworkRequestEvent.swift
//  WiFiNetworkSharingDemo
//
//  Created by Itsuki on 2025/12/14.
//

import Foundation

enum NetworkRequestEvent: Codable {
    case request
    // The actual network information will be delivered to the networkSharingCharacteristic
    // this is only for whether if the askToShareUI is presented successfully
    case response(error: String?)
    
    var isRequest: Bool {
        if case .request = self {
            return true
        }
        return false
    }
    
    var isResponse: Bool {
        if case .response(_) = self {
            return true
        }
        return false
    }
    
    var responseError: String? {
        if case .response(error: let error) = self {
            return error
        }
        return nil
    }
}
