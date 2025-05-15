//
//  TrustPartnerViewModel.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/19.
//

// File: TrustPartnerViewModel.swift

import Foundation
import SwiftUI

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
		}
	}
	
	func addTrustPartner(name: String, phoneNumber: String) {
		if trustPartners.contains(where: { $0.phoneNumber == phoneNumber }) {
			print("ViewModel: Partner with phone number \(phoneNumber) already exists.")
			return
		}
		var newPartner = TrustPartner(name: name, phoneNumber: phoneNumber)
		if trustPartners.isEmpty {
			newPartner.isPrimary = true
		}
		trustPartners.append(newPartner)
		saveTrustPartners()
		print("ViewModel: addTrustPartner completed. Partner: \(newPartner.name). isAnyPartnerSelectedAsPrimary is now: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
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
		
		saveTrustPartners() // This will print its own debug line too
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
		// Only save if a change actually occurred or if we want to enforce save regardless
		if changed || !trustPartners.contains(where: { $0.isPrimary }) { // Save if changed OR no primary exists (shouldn't happen if logic is correct)
			saveTrustPartners()
		}
		print("ViewModel: setPrimaryPartner completed for \(partnerToMakePrimary.name). isAnyPartnerSelectedAsPrimary is now: \(self.isAnyPartnerSelectedAsPrimary)") // DEBUG
	}
}
