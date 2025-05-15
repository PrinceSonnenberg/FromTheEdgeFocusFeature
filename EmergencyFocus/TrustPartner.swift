//
//  TrustPartner.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/16.
//

import Foundation

struct TrustPartner: Identifiable, Codable, Hashable {
	var id = UUID() // For Identifiable and list iteration
	var name: String
	var phoneNumber: String
	var isPrimary: Bool = false // To mark the currently active partner for "Get Help"
}
