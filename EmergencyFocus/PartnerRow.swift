//
// PartnerRow.swift
// EmergencyFocus
//
// Created by Prince Ezra on 2025/05/19.
//

import SwiftUI

struct PartnerRow: View {
	let partner: TrustPartner
	let isPrimary: Bool
	let onSelectAsPrimary: () -> Void
	
	var body: some View {
		// VStack to act as the card container
		VStack(alignment: .leading, spacing: 0) { // Use spacing 0 if padding handles inner spacing
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text(partner.name)
						.font(.headline)
						.foregroundColor(Color(.label)) // Ensure good contrast on card background
					Text(partner.phoneNumber)
						.font(.subheadline)
						.foregroundColor(Color(.secondaryLabel))
				}
				Spacer() // Pushes the checkmark or button to the right
				
				if isPrimary {
					Image(systemName: "checkmark.circle.fill")
						.foregroundColor(.green)
						.font(.title2)
						.transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .center)))
				} else {
					Button {
						onSelectAsPrimary()
					} label: {
						Text("Set Active")
							.font(.caption)
							.padding(.horizontal, 8)
							.padding(.vertical, 4)
							.background(Color.blue.opacity(0.1))
							.foregroundColor(.blue)
							.cornerRadius(8)
					}
					.buttonStyle(PlainButtonStyle())
					.transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .center)))
				}
			}
			.padding() // Internal padding for the card content
		}
		.background(Color(.secondarySystemGroupedBackground)) // Card background color
		.cornerRadius(10) // Rounded corners for the card
								// Optional: Add a subtle shadow to lift the card
								// .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
								// Note: .padding(.vertical, 8) from the old row style is removed here,
								// as spacing will be handled between cards in the List.
	}
}

// Preview for PartnerRow (updated to reflect card style)
#Preview {
	@State var primaryPartnerId: UUID? = TrustPartner(name: "Jane Doe", phoneNumber: "555-1234", isPrimary: true).id
	let mockPartner1 = TrustPartner(name: "Jane Doe", phoneNumber: "555-1234", isPrimary: true)
	let mockPartner2 = TrustPartner(name: "John Smith", phoneNumber: "555-5678", isPrimary: false)
	
	return ScrollView { // Use ScrollView for previewing cards with spacing
		VStack(spacing: 12) { // Spacing between cards
			Text("Card Style Preview:")
				.font(.title)
				.padding(.bottom)
			
			PartnerRow(partner: mockPartner1, isPrimary: primaryPartnerId == mockPartner1.id, onSelectAsPrimary: {
				withAnimation(.spring()) { primaryPartnerId = mockPartner1.id }
			})
			
			PartnerRow(partner: mockPartner2, isPrimary: primaryPartnerId == mockPartner2.id, onSelectAsPrimary: {
				withAnimation(.spring()) { primaryPartnerId = mockPartner2.id }
			})
			
			// Example of a card with a shadow (uncomment shadow in PartnerRow to see)
			// PartnerRow(partner: TrustPartner(name: "Shadow Card", phoneNumber: "555-0000"), isPrimary: false, onSelectAsPrimary: {})
		}
		.padding()
	}
	.background(Color(.systemGroupedBackground)) // Simulate list background
}
