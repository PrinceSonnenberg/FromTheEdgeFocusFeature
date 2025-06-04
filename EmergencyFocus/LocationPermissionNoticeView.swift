//
//  LocationPermissionNoticeView.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/06/02.
//

//
// LocationPermissionNoticeView.swift
// EmergencyFocus
//
// Created by Prince Ezra on 2025/06/02.
//

// File: LocationPermissionNoticeView.swift
import SwiftUI
import CoreLocation // For CLAuthorizationStatus
						  // import UIKit // For UIFeedbackGenerator

struct LocationPermissionNoticeView: View {
	@ObservedObject var locationManager: LocationManager
	// To ensure haptic plays only once per effective appearance
	@State private var hasTriggeredHapticForCurrentStatus: Bool = false
	@State private var lastSeenStatus: CLAuthorizationStatus? = nil
	
	
	var body: some View {
		// Only construct and show the banner if permission is denied or restricted.
		let shouldShowBanner = locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted
		
		if shouldShowBanner {
			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .top) {
					Image(systemName: iconNameForStatus())
						.foregroundColor(iconColorForStatus())
						.font(.title3)
						.padding(.trailing, 4)
					
					VStack(alignment: .leading, spacing: 4) {
						Text(titleForStatus())
							.font(.headline)
							.fontWeight(.semibold)
						Text(messageForStatus())
							.font(.caption)
							.foregroundColor(.secondary)
							.lineLimit(nil)
					}
					Spacer()
				}
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
			.padding()
			.frame(maxWidth: .infinity)
			.background(backgroundColorForStatus())
			.cornerRadius(12)
			.padding(.horizontal)
			// This transition is applied when the view is added/removed from the hierarchy
			.transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
											removal: .move(edge: .top).combined(with: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)))))
			.onAppear {
				// Play haptic only when the status newly changes to denied/restricted
				if lastSeenStatus != locationManager.authorizationStatus {
					let haptic = UINotificationFeedbackGenerator()
					haptic.notificationOccurred(.warning)
					lastSeenStatus = locationManager.authorizationStatus // Update last seen status
				}
			}
			.onChange(of: locationManager.authorizationStatus) { newStatus in
				// Play haptic if the banner becomes visible due to a status change to denied/restricted
				if (newStatus == .denied || newStatus == .restricted) && !(lastSeenStatus == .denied || lastSeenStatus == .restricted) {
					let haptic = UINotificationFeedbackGenerator()
					haptic.notificationOccurred(.warning)
				}
				lastSeenStatus = newStatus // Always update last seen status
			}
			
		} else {
			EmptyView()
				.onAppear {
					// Update status when banner is not shown, so haptic can trigger if it appears next
					if locationManager.authorizationStatus != .denied && locationManager.authorizationStatus != .restricted {
						lastSeenStatus = locationManager.authorizationStatus
					}
				}
		}
	}
	
	// MARK: - Helper Functions for UI Content
	private func iconNameForStatus() -> String {
		switch locationManager.authorizationStatus {
			case .denied: return "location.slash.fill"
			case .restricted: return "exclamationmark.lock.fill"
			default: return "questionmark.circle"
		}
	}
	
	private func iconColorForStatus() -> Color {
		switch locationManager.authorizationStatus {
			case .denied: return .orange
			case .restricted: return .red
			default: return .gray
		}
	}
	
	private func titleForStatus() -> String {
		switch locationManager.authorizationStatus {
			case .denied: return "Location Disabled"
			case .restricted: return "Location Restricted"
			default: return ""
		}
	}
	
	private func messageForStatus() -> String {
		switch locationManager.authorizationStatus {
			case .denied:
				return "To include your location in emergency messages, please enable Location Services for this app in Settings. Location will not be sent until enabled."
			case .restricted:
				return "Location services are restricted on this device (e.g., by Screen Time or parental controls) and cannot be enabled for this app at this time. Emergency messages will not include location."
			default: return ""
		}
	}
	
	private func backgroundColorForStatus() -> Color {
		switch locationManager.authorizationStatus {
			case .denied: return Color.orange.opacity(0.15)
			case .restricted: return Color.red.opacity(0.15)
			default: return Color.clear
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
		}
	}
}

// MARK: - Preview
#Preview {
	class MockLocationManager: LocationManager {
		convenience init(status: CLAuthorizationStatus) {
			self.init()
			self.authorizationStatus = status
		}
	}
	
	return ScrollView {
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
			Spacer()
		}
		.padding()
		.animation(.spring(), value: UUID()) // For preview transitions if status changes
	}
}
