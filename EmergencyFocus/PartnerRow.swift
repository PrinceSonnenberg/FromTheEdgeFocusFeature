//
//  PartnerRow.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/19.
//

import SwiftUI

struct PartnerRow: View {
	// Input properties for the row
	let partner: TrustPartner // Assumes TrustPartner.swift exists and is in your target
	let isPrimary: Bool
	let onSelectAsPrimary: () -> Void // Callback when "Set Active" is tapped
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 4) {
				Text(partner.name)
					.font(.headline)
				Text(partner.phoneNumber)
					.font(.subheadline)
					.foregroundColor(.gray)
			}
			
			Spacer() // Pushes the checkmark or button to the right
			
			if isPrimary {
				Image(systemName: "checkmark.circle.fill")
					.foregroundColor(.green)
					.font(.title2) // Make checkmark a bit bigger
			} else {
				// Button to make this partner the active primary one
				Button {
					onSelectAsPrimary()
				} label: {
					Text("Set Active")
						.font(.caption) // Smaller font for this button
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(Color.blue.opacity(0.1)) // Subtle background
						.foregroundColor(.blue)
						.cornerRadius(8)
				}
				.buttonStyle(PlainButtonStyle()) // Important for tappable buttons in List rows
			}
		}
		.padding(.vertical, 8) // Add some vertical padding to each row for better spacing
	}
}

// Preview for PartnerRow
#Preview {
	// Create some mock data for the preview
	let mockPartner1 = TrustPartner(name: "Jane Doe", phoneNumber: "555-1234", isPrimary: true)
	let mockPartner2 = TrustPartner(name: "John Smith", phoneNumber: "555-5678", isPrimary: false)
	
	return Group {
		PartnerRow(partner: mockPartner1, isPrimary: true, onSelectAsPrimary: {
			print("Set \(mockPartner1.name) as primary (Preview)")
		})
		.padding()
		.previewLayout(.sizeThatFits)
		.previewDisplayName("Primary Partner")
		
		PartnerRow(partner: mockPartner2, isPrimary: false, onSelectAsPrimary: {
			print("Set \(mockPartner2.name) as primary (Preview)")
		})
		.padding()
		.previewLayout(.sizeThatFits)
		.previewDisplayName("Non-Primary Partner")
		
		// Example of how it might look in a List
		List {
			PartnerRow(partner: mockPartner1, isPrimary: true, onSelectAsPrimary: {})
			PartnerRow(partner: mockPartner2, isPrimary: false, onSelectAsPrimary: {})
		}
		.previewDisplayName("In a List")
	}
}
