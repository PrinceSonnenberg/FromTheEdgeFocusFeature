//
//  LocationPermissionNoticeView.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/06/02.
//

// File: LocationPermissionNoticeView.swift

import SwiftUI
import CoreLocation // For CLAuthorizationStatus

struct LocationPermissionNoticeView: View {
	// This view observes the LocationManager passed to it.
	@ObservedObject var locationManager: LocationManager
	
	var body: some View {
		// Only construct and show the banner if permission is denied or restricted.
		if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .top) {
					Image(systemName: iconNameForStatus())
						.foregroundColor(iconColorForStatus())
						.font(.title3) // Slightly larger icon
						.padding(.trailing, 4)
					
					VStack(alignment: .leading, spacing: 4) {
						Text(titleForStatus())
							.font(.headline)
							.fontWeight(.semibold)
						
						Text(messageForStatus())
							.font(.caption)
							.foregroundColor(.secondary)
							.lineLimit(nil) // Allow multiple lines
					}
					Spacer() // Pushes content to the left
				}
				
				// Only show the "Open App Settings" button if permission is .denied,
				// as .restricted usually means the user cannot change it themselves.
				if locationManager.authorizationStatus == .denied {
					Button(action: openAppSettings) {
						Text("Open App Settings")
							.font(.caption)
							.fontWeight(.medium)
							.padding(.vertical, 6)
							.padding(.horizontal, 10)
							.background(Color.blue.opacity(0.15))
							.foregroundColor(.blue)
							.cornerRadius(8)
					}
					.padding(.top, 4)
				}
			}
			.padding() // Padding inside the banner
			.frame(maxWidth: .infinity) // Make the banner take full available width
			.background(backgroundColorForStatus()) // Use a subtle warning color
			.cornerRadius(12) // Rounded corners for the banner
			.padding(.horizontal) // Padding around the banner itself
										 // .padding(.top, 8) // Optional: Add space above the banner if needed in parent
			.transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
											removal: .opacity.combined(with: .scale(scale: 0.95)))) // Animation
		} else {
			// If permission is granted, not determined, or any other state, show nothing.
			EmptyView()
		}
	}
	
	// MARK: - Helper Functions for UI Content
	
	private func iconNameForStatus() -> String {
		switch locationManager.authorizationStatus {
			case .denied:
				return "location.slash.fill"
			case .restricted:
				return "exclamationmark.lock.fill" // Or "hand.raised.slash.fill"
			default:
				return "questionmark.circle" // Fallback, should not be seen
		}
	}
	
	private func iconColorForStatus() -> Color {
		switch locationManager.authorizationStatus {
			case .denied:
				return .orange
			case .restricted:
				return .red
			default:
				return .gray
		}
	}
	
	private func titleForStatus() -> String {
		switch locationManager.authorizationStatus {
			case .denied:
				return "Location Disabled"
			case .restricted:
				return "Location Restricted"
			default:
				return "" // Fallback
		}
	}
	
	private func messageForStatus() -> String {
		switch locationManager.authorizationStatus {
			case .denied:
				return "To include your location in emergency messages, please enable Location Services for this app in Settings. Location will not be sent until enabled."
			case .restricted:
				return "Location services are restricted on this device (e.g., by Screen Time or parental controls) and cannot be enabled for this app at this time. Emergency messages will not include location."
			default:
				return "" // Fallback
		}
	}
	
	private func backgroundColorForStatus() -> Color {
		switch locationManager.authorizationStatus {
			case .denied:
				return Color.orange.opacity(0.15)
			case .restricted:
				return Color.red.opacity(0.15)
			default:
				return Color.clear
		}
	}
	
	private func openAppSettings() {
		guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
			print("Error: Could not create settings URL string.")
			return
		}
		if UIApplication.shared.canOpenURL(settingsUrl) {
			UIApplication.shared.open(settingsUrl, completionHandler: nil)
		} else {
			print("Error: Cannot open app settings URL.")
			// You might want to show an alert to the user in this rare case.
		}
	}
}

// MARK: - Preview

#Preview {
	// Mock LocationManager for different preview states
	class MockLocationManager: LocationManager {
		convenience init(status: CLAuthorizationStatus) {
			self.init() // Call designated initializer of real LocationManager
			self.authorizationStatus = status // Override the published property for the mock
		}
	}
	
	return ScrollView { // Use ScrollView to see how banner interacts with content
		VStack(spacing: 20) {
			Text("Some content above the banner...")
				.padding()
			
			LocationPermissionNoticeView(locationManager: MockLocationManager(status: .denied))
				.previewDisplayName("Status: Denied")
			
			LocationPermissionNoticeView(locationManager: MockLocationManager(status: .restricted))
				.previewDisplayName("Status: Restricted")
			
			Text("Simulating Granted State (Banner Hidden):")
			LocationPermissionNoticeView(locationManager: MockLocationManager(status: .authorizedWhenInUse))
				.previewDisplayName("Status: Authorized (Hidden)")
			
			Text("Simulating Not Determined State (Banner Hidden):")
			LocationPermissionNoticeView(locationManager: MockLocationManager(status: .notDetermined))
				.previewDisplayName("Status: Not Determined (Hidden)")
			
			Spacer()
		}
		.padding() // Padding for the VStack content in preview
	}
}
