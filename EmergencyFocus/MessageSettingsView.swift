//
//  MessageSettingsView.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/20.
//

// File: MessageSettingsView.swift

// File: MessageSettingsView.swift
import SwiftUI
import CoreLocation // For CLAuthorizationStatus

struct MessageSettingsView: View {
	// AppStorage for message preferences (these are global)
	@AppStorage("useCustomEmergencyMessage_v1") private var useCustomMessage: Bool = false
	@AppStorage("customEmergencyMessageText_v1") private var customMessageText: String = "I'm using a custom message and need help. Please contact me."
	@AppStorage("includeLocationInMessage_v1") private var includeLocationInSettings: Bool = true // User's preference within the app
	
	let defaultEmergencyMessageTemplate = "You are part of my safety circle, {NAME}. I am feeling vulnerable right now and need you to contact me."
	
	// Observe the LocationManager instance passed from the parent view
	@ObservedObject var locationManager: LocationManager
	@Environment(\.presentationMode) var presentationMode
	
	// State for content appearance animation
	@State private var contentHasAppeared: Bool = false
	
	// Computed property to determine if the app has sufficient location permission
	private var hasLocationPermission: Bool {
		locationManager.authorizationStatus == .authorizedWhenInUse ||
		locationManager.authorizationStatus == .authorizedAlways
	}
	
	init(locationManager: LocationManager) {
		self.locationManager = locationManager
		// Note: Moving UITextView appearance modification to TextEditor's specific onAppear/onDisappear
	}
	
	var body: some View {
		NavigationView {
			Form {
				Section(header: Text("Emergency Message Content")) {
					Toggle("Use Custom Message", isOn: $useCustomMessage.animation())
					
					if useCustomMessage {
						VStack(alignment: .leading, spacing: 8) {
							Text("Enter your custom message.\n'{NAME}' will be replaced with the partner's name. \nIf 'Include Location' is on (and app permission granted), location will be added.")
								.font(.caption)
								.foregroundColor(.secondary)
							
							TextEditor(text: $customMessageText)
								.frame(minHeight: 100, maxHeight: 200)
								.overlay(
									RoundedRectangle(cornerRadius: 8)
										.stroke(Color.gray.opacity(0.3), lineWidth: 1)
								)
								.onAppear { UITextView.appearance().backgroundColor = .clear }
								.onDisappear { UITextView.appearance().backgroundColor = nil }
								.padding(.vertical, 5)
						}
					} else {
						VStack(alignment: .leading, spacing: 4) {
							Text("The app will use the default message:")
								.font(.caption)
								.foregroundColor(.secondary)
							Text(defaultEmergencyMessageTemplate.replacingOccurrences(of: "{NAME}", with: "[Partner's Name]"))
								.italic()
								.font(.callout)
						}
						.padding(.vertical, 5)
					}
				}
				
				Section(header: Text("Location Sharing In Message")) {
					if hasLocationPermission {
						Toggle("Include Location Data", isOn: $includeLocationInSettings)
						Text("If enabled, your approximate location will be added to the emergency message.")
							.font(.caption)
							.foregroundColor(.secondary)
					} else {
						VStack(alignment: .leading, spacing: 8) {
							Toggle("Include Location Data", isOn: $includeLocationInSettings)
								.disabled(true)
							
							if locationManager.authorizationStatus == .denied {
								Text("App-level location permission is currently disabled. To enable location sharing in messages, first grant location access to this app in Settings.")
									.font(.caption)
									.foregroundColor(.orange)
								Button("Open App Settings") { openAppSettings() }
									.font(.caption)
							} else if locationManager.authorizationStatus == .restricted {
								Text("App-level location permission is restricted on this device (e.g., by parental controls). Location cannot be included in messages.")
									.font(.caption)
									.foregroundColor(.red)
							} else if locationManager.authorizationStatus == .notDetermined {
								Text("Location permission has not been set yet. Please return to the main screen; the app will request permission if needed.")
									.font(.caption)
									.foregroundColor(.orange)
							}
						}
						.padding(.vertical, 5)
					}
				}
			}
			.navigationTitle("Message Settings")
			.navigationBarItems(trailing: Button("Done") {
				presentationMode.wrappedValue.dismiss()
			})
			// Animation modifiers for the content of the sheet
			.scaleEffect(contentHasAppeared ? 1.0 : 0.93) // Start slightly smaller
			.opacity(contentHasAppeared ? 1.0 : 0.0)    // Start transparent
			.onAppear {
				withAnimation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0)) {
					contentHasAppeared = true
				}
			}
		}
		.navigationViewStyle(.stack) // Apply to the NavigationView
	}
	
	private func openAppSettings() {
		guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
			print("Error: Could not create settings URL string for MessageSettingsView.")
			return
		}
		if UIApplication.shared.canOpenURL(settingsUrl) {
			UIApplication.shared.open(settingsUrl)
		} else {
			print("Error: Cannot open app settings URL from MessageSettingsView.")
		}
	}
}

// MARK: - Preview
#Preview {
	// Mock LocationManager for different preview states
	class MockSettingsLocationManager: LocationManager {
		convenience init(status: CLAuthorizationStatus) {
			self.init()
			self.authorizationStatus = status
		}
	}
	
	return Group {
		MessageSettingsView(locationManager: MockSettingsLocationManager(status: .authorizedWhenInUse))
			.previewDisplayName("Location Authorized")
		// Add other previews if needed
	}
}
