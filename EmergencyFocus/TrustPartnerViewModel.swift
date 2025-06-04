//
//  TrustPartnerViewModel.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/19.
//

//
// TrustPartnerViewModel.swift
// EmergencyFocus
//
// Created by Prince Ezra on 2025/05/19.
//

// File: TrustPartnerViewModel.swift
import Foundation
import SwiftUI

enum AddPartnerError: LocalizedError {
	case blankNumber
	case invalidFormat
	case duplicateNumber
	
	var errorDescription: String? {
		switch self {
			case .blankNumber:
				return "The phone number cannot be blank. Please enter a valid number."
			case .invalidFormat:
				return "The phone number format is incorrect. Please enter a valid South African mobile number (e.g., 0721234567 or +27721234567)."
			case .duplicateNumber:
				return "This phone number is already in your Trust Partners list."
		}
	}
}

class TrustPartnerViewModel: ObservableObject {
	@Published var trustPartners: [TrustPartner] = []
	
	var primaryPartner: TrustPartner? {
		trustPartners.first(where: { $0.isPrimary })
	}
	
	var isAnyPartnerSelectedAsPrimary: Bool {
		let result = primaryPartner != nil
		// print("ViewModel: isAnyPartnerSelectedAsPrimary is: \(result)") // Optional DEBUG
		return result
	}
	
	private let trustPartnersKey = "trustPartners_v2"
	
	init() {
		loadTrustPartners()
		print("ViewModel: init completed. isAnyPartnerSelectedAsPrimary is: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
	}
	
	// --- Helper function to clean phone numbers ---
	private func cleanPhoneNumber(_ phoneNumber: String) -> String {
		// Removes common non-numeric characters, keeps '+' for international numbers
		// Allows digits 0-9 and the plus sign.
		return phoneNumber.components(separatedBy: CharacterSet(charactersIn: "0123456789+").inverted).joined()
	}
	
	// --- Helper function to validate South African mobile numbers ---
	private func isValidSouthAfricanMobileNumber(phoneNumber: String) -> Bool {
		let cleanedNumber = phoneNumber // Assumes it's already cleaned when this is called internally
		
		// Regex for local SA mobile numbers: 0 followed by 6, 7, or 8, then 8 digits.
		// Example: 0601234567, 0721234567, 0831234567
		let localMobileRegex = "^0[678]\\d{8}$"
		
		// Regex for international SA mobile numbers: +27 followed by 6, 7, or 8 (after dropping local '0'), then 8 digits.
		// Example: +27601234567, +27721234567, +27831234567
		let internationalMobileRegex = "^\\+27[678]\\d{8}$"
		
		if let _ = cleanedNumber.range(of: localMobileRegex, options: .regularExpression) {
			return true
		}
		
		if let _ = cleanedNumber.range(of: internationalMobileRegex, options: .regularExpression) {
			return true
		}
		
		return false
	}
	
	func loadTrustPartners() {
		guard let data = UserDefaults.standard.data(forKey: trustPartnersKey) else {
			self.trustPartners = []
			print("ViewModel: loadTrustPartners - No data found. Partners empty. isAnyPartnerSelectedAsPrimary: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
			return
		}
		do {
			let decodedPartners = try JSONDecoder().decode([TrustPartner].self, from: data)
			self.trustPartners = decodedPartners
			ensurePrimaryPartnerConsistency()
			print("ViewModel: loadTrustPartners - Loaded \(self.trustPartners.count) partners. isAnyPartnerSelectedAsPrimary after consistency: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
		} catch {
			print("Failed to decode trust partners: \(error)")
			self.trustPartners = []
		}
	}
	
	func saveTrustPartners() {
		do {
			let encodedData = try JSONEncoder().encode(trustPartners)
			UserDefaults.standard.set(encodedData, forKey: trustPartnersKey)
			print("ViewModel: saveTrustPartners - Saved \(trustPartners.count) partners. isAnyPartnerSelectedAsPrimary: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
		} catch {
			print("Failed to encode trust partners: \(error)")
		}
	}
	
	private func ensurePrimaryPartnerConsistency() {
		var madeChange = false
		if trustPartners.filter({ $0.isPrimary }).count == 0 && !trustPartners.isEmpty {
			trustPartners[0].isPrimary = true
			madeChange = true
		} else if trustPartners.filter({ $0.isPrimary }).count > 1 {
			var foundFirstPrimary = false
			for i in trustPartners.indices {
				if trustPartners[i].isPrimary {
					if !foundFirstPrimary {
						foundFirstPrimary = true
					} else {
						trustPartners[i].isPrimary = false
						madeChange = true
					}
				}
			}
		}
		if madeChange {
			print("ViewModel: ensurePrimaryPartnerConsistency made changes.") // DEBUG
																									// saveTrustPartners() // Save if changes were made by consistency logic
		}
	}
	
	func addTrustPartner(name: String, phoneNumber: String) -> AddPartnerError? {
		let processedPhoneNumber = cleanPhoneNumber(phoneNumber)
		
		guard !processedPhoneNumber.isEmpty else {
			print("ViewModel: Phone number is blank after cleaning. Partner not added.")
			return .blankNumber
		}
		
		guard isValidSouthAfricanMobileNumber(phoneNumber: processedPhoneNumber) else {
			print("ViewModel: Invalid South African mobile number format for '\(phoneNumber)' (cleaned: '\(processedPhoneNumber)'). Partner not added.")
			return .invalidFormat
		}
		
		// Check for duplicates using the processed phone number
		if trustPartners.contains(where: { cleanPhoneNumber($0.phoneNumber) == processedPhoneNumber }) {
			print("ViewModel: Partner with phone number \(processedPhoneNumber) already exists.")
			return .duplicateNumber
		}
		
		var newPartner = TrustPartner(name: name, phoneNumber: processedPhoneNumber)
		if trustPartners.isEmpty {
			newPartner.isPrimary = true
		}
		trustPartners.append(newPartner)
		saveTrustPartners()
		print("ViewModel: addTrustPartner completed. Partner: \(newPartner.name) with number \(newPartner.phoneNumber). isAnyPartnerSelectedAsPrimary is now: \(self.isAnyPartnerSelectedAsPrimary)")
		return nil // Success
	}
	
	func removeTrustPartner(_ partnerToRemove: TrustPartner) {
		print("ViewModel: removeTrustPartner called for \(partnerToRemove.name) with ID \(partnerToRemove.id)") // DEBUG
		let initialCount = trustPartners.count
		let wasPrimary = partnerToRemove.isPrimary
		
		trustPartners.removeAll { $0.id == partnerToRemove.id }
		
		let finalCount = trustPartners.count
		print("ViewModel: trustPartners count changed from \(initialCount) to \(finalCount). Element removed: \(initialCount != finalCount)") // DEBUG
		
		if wasPrimary && !trustPartners.isEmpty && !trustPartners.contains(where: { $0.isPrimary }) {
			print("ViewModel: Removed partner (\(partnerToRemove.name)) was primary. Setting new primary: \(trustPartners[0].name)") // DEBUG
			trustPartners[0].isPrimary = true
		} else if wasPrimary && trustPartners.isEmpty {
			print("ViewModel: Removed partner (\(partnerToRemove.name)) was primary. List is now empty.") // DEBUG
		}
		saveTrustPartners()
	}
	
	func removeAllTrustPartners() {
		trustPartners.removeAll()
		saveTrustPartners()
		print("ViewModel: removeAllTrustPartners completed. isAnyPartnerSelectedAsPrimary is now: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
	}
	
	func setPrimaryPartner(_ partnerToMakePrimary: TrustPartner) {
		var changed = false
		for i in trustPartners.indices {
			let shouldBePrimary = (trustPartners[i].id == partnerToMakePrimary.id)
			if trustPartners[i].isPrimary != shouldBePrimary {
				changed = true
			}
			trustPartners[i].isPrimary = shouldBePrimary
		}
		
		if changed || !trustPartners.contains(where: { $0.isPrimary }) {
			saveTrustPartners()
		}
		print("ViewModel: setPrimaryPartner completed for \(partnerToMakePrimary.name). isAnyPartnerSelectedAsPrimary is now: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
	}
}
