//
//  WiFiInfrastructure+Extensions.swift
//  WiFiNetworkSharingDemo
//
//  Created by Itsuki on 2025/12/14.
//

import WiFiInfrastructure
import SwiftUI

extension WINetworkSharingProvider.Network.SecurityPolicy {
    var stringRepresentation: String {
        switch self {
        case .open:
            "Open"
        case .owe:
            "OWE"
        case .wep:
            "WEP"
        case .wpa:
            "WPA"
        case .wpa2:
            "WPA2"
        case .wpa3:
            "WPA3-SAE"
        @unknown default:
            "Unknown"
        }
    }
}

extension WINetworkSharingProvider.Network.Credentials {
    var stringRepresentation: String {
        switch self {
        case .none:
            "No credential needed."
        case .password(let password):
            "Password: \(password.prefix(1))***\(password.suffix(1))"
        @unknown default:
            "Unknown"
        }
    }
}

extension WISSID {
    var stringRepresentation: String? {
        // some common encodings to try
        let encodings: [String.Encoding] = [.utf8, .utf16, .utf32, .ascii, .isoLatin1, .iso2022JP, .isoLatin2, .shiftJIS, .windowsCP1250, .windowsCP1251, .windowsCP1252, .windowsCP1253, .windowsCP1254, .macOSRoman, .japaneseEUC, .unicode]
        for encoding in encodings {
            if let string = self.stringRepresentation(encoding: encoding) {
                return string
            }
        }
        return nil
    }
}
