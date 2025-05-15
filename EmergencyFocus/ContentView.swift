	//
	//  ContentView.swift
	//  EmergencyFocus
	//
	//  Created by Prince Ezra on 2025/05/15.
	//

	// File: EmergencyContactView.swift (or ContentView.swift)

	import SwiftUI
	import MessageUI
	import CoreLocation
	import ContactsUI

	// Assumes all necessary component files (LocationPermissionNoticeView, MessageSettingsView, etc.) exist.

	struct EmergencyContactView: View {
		@StateObject private var viewModel = TrustPartnerViewModel()
		@StateObject private var locationManager = LocationManager() // Central LocationManager
		
		// UI State
		@State private var showingContactPicker = false
		@State private var showingMessageComposer = false
		@State private var messageBody: String = ""
		@State private var isPreparingMessage = false
		@State private var showingMessageSettings = false
		
		// Confirmation Dialog State
		@State private var showingClearConfirmation = false
		@State private var partnerToClear: TrustPartner? = nil
		@State private var showingDeleteAllConfirmation = false
		
		// AppStorage for one-time alert
		@AppStorage("hasShownTrustPartnerWelcomeAlert_v1") private var hasShownWelcomeAlert: Bool = false
		@State private var showingWelcomeAlert = false
		
		// Computed Properties for Button States
		var isGetHelpButtonActive: Bool {
			viewModel.isAnyPartnerSelectedAsPrimary && !isPreparingMessage
		}
		
		var shouldButtonJiggle: Bool {
			!viewModel.isAnyPartnerSelectedAsPrimary && !isPreparingMessage
		}
		
		// MARK: - Body
		var body: some View {
			NavigationView {
				VStack(spacing: 0) { // Main content VStack
					
					// --- INTEGRATE LocationPermissionNoticeView ---
					// It will only display content if status is .denied or .restricted
					LocationPermissionNoticeView(locationManager: locationManager)
					// Add padding below only if the banner is actually visible
						.padding(.bottom, (locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted) ? 8 : 0)
					// --- END INTEGRATION ---
					
					if viewModel.trustPartners.isEmpty {
						emptyStateView
					} else {
						partnersListView
					}
					
					if isPreparingMessage {
						ProgressView("Preparing message...").padding()
					}
					
					getHelpButton
				}
				.navigationTitle("Trust Partners")
				.toolbar {
					ToolbarItem(placement: .navigationBarTrailing) {
						Button {
							showingMessageSettings = true
						} label: {
							Image(systemName: "gearshape.fill")
						}
					}
				}
				.background(Color(.systemGroupedBackground).ignoresSafeArea()) // Standard background
				.onAppear(perform: onViewAppearLogic) // Call app-specific onAppear logic
				.alert("Welcome to Trust Partners!", isPresented: $showingWelcomeAlert, actions: alertActions, message: alertMessage)
				.sheet(isPresented: $showingMessageSettings) {
					// Pass the locationManager instance to MessageSettingsView
					MessageSettingsView(locationManager: self.locationManager)
				}
				.sheet(isPresented: $showingContactPicker, content: contactPickerSheet)
				.sheet(isPresented: $showingMessageComposer, content: messageComposerSheet)
				.confirmationDialog(
					"Are you sure you want to remove \(partnerToClear?.name ?? "this partner")?",
					isPresented: $showingClearConfirmation,
					titleVisibility: .visible,
					actions: clearPartnerDialogActions
				)
				.confirmationDialog(
					"Are you sure you want to remove all Trust Partners?",
					isPresented: $showingDeleteAllConfirmation,
					titleVisibility: .visible,
					actions: clearAllPartnersDialogActions
				)
			}
			.navigationViewStyle(.stack)
		}
		
		// MARK: - Extracted UI Components (emptyStateView, partnersListView, getHelpButton)
		// These should be the same as your last working "reverted visual style" version
		private var emptyStateView: some View {
			VStack {
				Spacer()
				VStack(spacing: 20) {
					Text("Tap the (+) button below to add your first Trust Partner.")
						.font(.title3).fontWeight(.medium).foregroundColor(Color(.secondaryLabel))
						.multilineTextAlignment(.center).padding(.horizontal, 40)
					Button { showingContactPicker = true } label: {
						Image(systemName: "plus.circle.fill").resizable().scaledToFit()
							.frame(width: 80, height: 80).foregroundColor(.blue)
					}
				}
				.padding(.bottom, 30)
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.clear) // Ensure it's transparent if it sits above ZStack background (not relevant here)
		}
		
		private var partnersListView: some View {
			List {
				Section(header: Text("Your Trust Partners").font(.headline).padding(.top)) {
					ForEach(viewModel.trustPartners) { partner in
						PartnerRow(partner: partner, isPrimary: partner.id == viewModel.primaryPartner?.id) {
							viewModel.setPrimaryPartner(partner)
						}
						.swipeActions(edge: .trailing) {
							Button(role: .destructive) {
								self.partnerToClear = partner
								self.showingClearConfirmation = true
							} label: { Label("Delete", systemImage: "trash.fill") }
						}
					}
				}
				Section(header: Text("Actions")) {
					Button { showingContactPicker = true } label: {
						HStack { Image(systemName: "plus.circle.fill"); Text("Add Another Partner") }
							.foregroundColor(.blue)
					}
					if viewModel.trustPartners.count > 1 {
						Button("Remove All Partners", role: .destructive) {
							showingDeleteAllConfirmation = true
						}
					}
				}
			}
			.listStyle(InsetGroupedListStyle())
		}
		
		private var getHelpButton: some View {
			Button { Task { await prepareAndSendMessage() } } label: {
				Text("Get Help").font(.title2).fontWeight(.bold).foregroundColor(.white)
					.padding().frame(maxWidth: .infinity)
					.background(isGetHelpButtonActive ? Color.red : Color.gray).cornerRadius(12)
			}
			.disabled(!isGetHelpButtonActive)
			.jiggle(isEnabled: shouldButtonJiggle)
			.pulsatingGlow(isEnabled: isGetHelpButtonActive, glowColor: .red, maxRadius: 15)
			.padding([.horizontal, .bottom], 20)
		}
		
		// MARK: - Sheet and Alert Content Closures
		@ViewBuilder
		private func messageSettingsSheet() -> some View {
			// Pass the single locationManager instance
			MessageSettingsView(locationManager: self.locationManager)
		}
		
		@ViewBuilder
		private func contactPickerSheet() -> some View {
			NewContactPickerView { name, phoneNumber in
				if let name = name, let phoneNumber = phoneNumber {
					viewModel.addTrustPartner(name: name, phoneNumber: phoneNumber)
				}
			}
		}
		
		@ViewBuilder
		private func messageComposerSheet() -> some View {
			let currentPrimaryInSheet = viewModel.primaryPartner
			if let partner = currentPrimaryInSheet {
				MessageComposeView(recipients: [partner.phoneNumber], body: messageBody) { result in
					showingMessageComposer = false
				}
			} else {
				Group {
					Text("Error: No recipient available to send message.").padding()
						.onAppear { DispatchQueue.main.async { self.showingMessageComposer = false } }
				}
			}
		}
		
		@ViewBuilder
		private func alertActions() -> some View { Button("OK", role: .cancel) { } }
		
		private func alertMessage() -> Text {
			Text("This screen helps you manage your Trust Partners.\n\nAdd individuals you trust, and set one as 'Active'. The 'Get Help' button will use the active partner to send an emergency message with your location.")
		}
		
		@ViewBuilder
		private func clearPartnerDialogActions() -> some View {
			Button("Remove Partner", role: .destructive) {
				if let partner = partnerToClear { viewModel.removeTrustPartner(partner) }
				partnerToClear = nil
			}
			Button("Cancel", role: .cancel) { partnerToClear = nil }
		}
		
		@ViewBuilder
		private func clearAllPartnersDialogActions() -> some View {
			Button("Remove All", role: .destructive) { viewModel.removeAllTrustPartners() }
			Button("Cancel", role: .cancel) {}
		}
		
		// MARK: - Lifecycle and Action Methods
		private func onViewAppearLogic() {
			// Logic for welcome alert
			if !hasShownWelcomeAlert {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					showingWelcomeAlert = true
					hasShownWelcomeAlert = true
				}
			}
			
			// Request location permission IF NOT YET DETERMINED when the main view appears
			if locationManager.authorizationStatus == .notDetermined {
				print("EmergencyContactView: Location status .notDetermined on appear, requesting permission.")
				// You might want to show a pre-permission priming alert/view here for more context
				// before calling the system prompt.
				locationManager.requestLocationPermission()
			} else {
				print("EmergencyContactView: Location status is \(locationManager.authorizationStatus.rawValue) on appear.")
			}
			// ViewModel loads its data in its init()
		}
		
		func prepareAndSendMessage() async {
			// Access AppStorage directly within this function's scope for user preferences
			@AppStorage("useCustomEmergencyMessage_v1") var useCustomMessage: Bool = false
			@AppStorage("customEmergencyMessageText_v1") var customMessageText: String = "I'm using a custom message and need help. Please contact me."
			@AppStorage("includeLocationInMessage_v1") var includeLocationInSettings: Bool = true // User's choice from MessageSettingsView
			
			let defaultEmergencyMessageTemplate = "You are part of my safety circle, {NAME}. I am feeling vulnerable right now and need you to contact me."
			
			guard let activePartner = viewModel.primaryPartner else {
				print("prepareAndSendMessage: GUARD FAILED - No activePartner from viewModel.")
				isPreparingMessage = false; return
			}
			isPreparingMessage = true
			
			var baseMessage: String
			if useCustomMessage {
				let trimmedCustomText = customMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
				if trimmedCustomText.isEmpty {
					baseMessage = defaultEmergencyMessageTemplate.replacingOccurrences(of: "{NAME}", with: activePartner.name)
					print("prepareAndSendMessage: Custom message was empty, using default.")
				} else {
					baseMessage = trimmedCustomText.replacingOccurrences(of: "{NAME}", with: activePartner.name)
				}
			} else {
				baseMessage = defaultEmergencyMessageTemplate.replacingOccurrences(of: "{NAME}", with: activePartner.name)
			}
			
			var finalMessageBody = baseMessage
			let currentStatus = locationManager.authorizationStatus // Get current status
			
			// Logic for appending location information
			if (currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways) && includeLocationInSettings {
				// Permission granted AND user wants to include location
				do {
					let timeoutDuration: TimeInterval = 10
					let fetchedLocationOptional: CLLocation? = try await withThrowingTaskGroup(of: CLLocation?.self, returning: CLLocation?.self) { group in
						group.addTask { return try await self.locationManager.fetchCurrentLocation() }
						group.addTask { try await Task.sleep(nanoseconds: UInt64(timeoutDuration * 1_000_000_000)); throw LocationError.timeout }
						if let firstResult = try await group.next() { group.cancelAll(); return firstResult } else { group.cancelAll(); return nil }
					}
					if let fetchedLoc = fetchedLocationOptional {
						let locationString = "My current location is approximately: https://maps.google.com/?q=\(fetchedLoc.coordinate.latitude),\(fetchedLoc.coordinate.longitude)"
						finalMessageBody += "\n\n\(locationString)"
					} else {
						finalMessageBody += "\n\n(Could not retrieve current location details.)"
					}
				} catch LocationError.permissionDenied { // This case should ideally be rare if initial status check is robust
					finalMessageBody += "\n\n(Location permission denied unexpectedly during fetch. Please check Settings.)"
				} catch LocationError.timeout {
					finalMessageBody += "\n\n(Could not retrieve location: timed out.)"
				} catch let otherError {
					finalMessageBody += "\n\n(Location services error: \(otherError.localizedDescription).)"
				}
			} else if !includeLocationInSettings { // User opted out in settings (app permission might be granted or not)
				finalMessageBody += "\n\n(Location sharing turned off by user in settings.)"
				print("prepareAndSendMessage: Location sharing turned off by user setting.")
			} else if currentStatus == .denied || currentStatus == .restricted { // App-level permission issue
				finalMessageBody += "\n\n(Location services disabled or restricted for this app.)"
			} else if currentStatus == .notDetermined { // Should ideally be resolved by .onAppear
				finalMessageBody += "\n\n(Location permission not yet determined. Please try again or check Settings.)"
			}
			
			self.messageBody = finalMessageBody
			
			if MFMessageComposeViewController.canSendText() {
				showingMessageComposer = true
			} else {
				print("Device cannot send text messages.")
			}
			isPreparingMessage = false
		}
	}

	#Preview {
		EmergencyContactView()
	}
