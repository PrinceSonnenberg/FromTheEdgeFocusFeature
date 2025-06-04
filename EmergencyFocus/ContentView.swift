//
// ContentView.swift
// EmergencyFocus
//
// Created by Prince Ezra on 2025/05/15.
//

// File: EmergencyContactView.swift (or ContentView.swift)
import SwiftUI
import MessageUI
import CoreLocation
import ContactsUI
// import UIKit // For UIFeedbackGenerator

// EmptyStateViewContent struct (as defined previously)
struct EmptyStateViewContent: View {
	@Binding var showingContactPicker: Bool
	
	var body: some View {
		VStack {
			Spacer()
			VStack(spacing: 24) {
				Image(systemName: "person.fill.badge.plus")
					.resizable()
					.scaledToFit()
					.frame(width: 70, height: 70)
					.foregroundColor(Color.gray.opacity(0.6))
					.padding(.bottom, 8)
				
				Text("Add Your First Trust Partner")
					.font(.title2)
					.fontWeight(.semibold)
					.foregroundColor(Color(.label))
				
				Text("Tap the (+) button below to select a contact who can help you in an emergency.")
					.font(.body)
					.foregroundColor(Color(.secondaryLabel))
					.multilineTextAlignment(.center)
					.padding(.horizontal, 45)
				
				Button { showingContactPicker = true } label: {
					Image(systemName: "plus.circle.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 65, height: 65)
						.foregroundColor(.blue)
				}
				.padding(.top, 16)
			}
			.padding(.bottom, 48)
			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.clear)
	}
}


struct EmergencyContactView: View {
	@StateObject private var viewModel = TrustPartnerViewModel()
	@StateObject private var locationManager = LocationManager()
	
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
	@AppStorage("hasShownTrustPartnerWelcomeAlert_v1") private var
	hasShownWelcomeAlert: Bool = false
	@State private var showingWelcomeAlert = false
	
	// States for add partner validation alerts
	@State private var showingAddPartnerErrorAlert = false
	@State private var addPartnerAlertMessage: String = ""
	
	// States for "Message Sent" confirmation
	@State private var showMessageSentConfirmation: Bool = false
	@State private var messageSentConfirmationDisappearTask: DispatchWorkItem? = nil
	
	
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
				LocationPermissionNoticeView(locationManager: locationManager)
					.padding(.bottom, (locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted) ? 8 : 0)
				
				if viewModel.trustPartners.isEmpty {
					emptyStateView // This is now EmptyStateViewContent
						.transition(.asymmetric(
							insertion: .move(edge: .bottom).combined(with: .opacity),
							removal: .move(edge: .top).combined(with: .opacity)
						))
				} else {
					// "Your Trust Partners" title placed above the List
					Text("Your Trust Partners")
						.font(.title3) // Using .title3 for a bit more prominence than .headline
						.fontWeight(.semibold) // Make it stand out
						.padding(.horizontal) // Standard horizontal padding
						.padding(.top, 16)    // Space above this text
						.padding(.bottom, 4)  // Reduced space between this text and the List
						.frame(maxWidth: .infinity, alignment: .leading) // Align to leading edge
					
					partnersCardList // The List view itself
						.transition(.asymmetric(
							insertion: .move(edge: .bottom).combined(with: .opacity),
							removal: .move(edge: .top).combined(with: .opacity)
						))
				}
				
				if isPreparingMessage {
					ProgressView("Preparing message...").padding()
						.transition(.opacity)
				}
				
				getHelpButton
			}
			.animation(.spring(response: 0.5, dampingFraction: 0.8), value: locationManager.authorizationStatus)
			.animation(.easeInOut(duration: 0.7), value: viewModel.trustPartners.isEmpty) // This animates the switch
			.animation(.easeInOut(duration: 0.3), value: isPreparingMessage)
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
			.background(Color(.systemGroupedBackground).ignoresSafeArea())
			.onAppear(perform: onViewAppearLogic)
			.alert("Welcome to Trust Partners!", isPresented: $showingWelcomeAlert,
					 actions: alertActions, message: alertMessage)
			.sheet(isPresented: $showingMessageSettings) {
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
			.alert("Could Not Add Partner", isPresented: $showingAddPartnerErrorAlert) {
				Button("OK", role: .cancel) { }
			} message: {
				Text(addPartnerAlertMessage)
			}
			.overlay(alignment: .center) {
				messageSentConfirmationView
			}
			.navigationViewStyle(.stack)
		}
	}
	
	// MARK: - Extracted UI Components
	private var emptyStateView: some View {
		EmptyStateViewContent(showingContactPicker: $showingContactPicker)
	}
	
	// Renamed to partnersCardList to reflect its content structure
	private var partnersCardList: some View {
		List {
			// Each PartnerRow is in its own Section to appear as a distinct card
			ForEach(viewModel.trustPartners) { partner in
				Section { // No header for individual partner card sections
					PartnerRow(partner: partner, isPrimary: partner.id == viewModel.primaryPartner?.id) {
						withAnimation(.spring()) {
							viewModel.setPrimaryPartner(partner)
						}
					}
					.listRowInsets(EdgeInsets()) // Remove default insets
					.swipeActions(edge: .trailing) {
						Button(role: .destructive) {
							self.partnerToClear = partner
							self.showingClearConfirmation = true
						} label: { Label("Delete", systemImage: "trash.fill") }
					}
				}
				// The InsetGroupedListStyle provides spacing between these sections.
				// You can add .listSectionSpacing(.compact) or .listSectionSpacing(someValue) to the List
				// if you want to further control the space between cards (sections).
			}
			
			// "Actions" Section - standard list rows
			Section(header: Text("Actions")
				.font(.headline)
				.textCase(nil)
			) {
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
		// .listSectionSpacing(8) // Example: Explicitly set spacing between sections (cards)
	}
	
	private var getHelpButton: some View {
		Button {
			let haptic = UIImpactFeedbackGenerator(style: .medium)
			haptic.impactOccurred()
			Task {
				await prepareAndSendMessage()
			}
		} label: {
			Text("Get Help").font(.title2).fontWeight(.bold).foregroundColor(.white)
				.padding().frame(maxWidth: .infinity)
				.background(isGetHelpButtonActive ? Color.red : Color.gray).cornerRadius(12)
				.shadow(color: Color.black.opacity(isGetHelpButtonActive ? 0.35 : 0.2),
						  radius: isGetHelpButtonActive ? 8 : 5,
						  x: 0,
						  y: isGetHelpButtonActive ? 5 : 3)
		}
		.disabled(!isGetHelpButtonActive)
		.jiggle(isEnabled: shouldButtonJiggle)
		.pulsatingGlow(isEnabled: isGetHelpButtonActive, glowColor: .red, maxRadius: 15)
		.padding([.horizontal, .bottom], 24)
	}
	
	// MARK: - Message Sent Confirmation View
	@ViewBuilder
	private var messageSentConfirmationView: some View {
		if showMessageSentConfirmation {
			VStack(spacing: 10) {
				Image(systemName: "checkmark.circle.fill")
					.resizable()
					.scaledToFit()
					.frame(width: 50, height: 50)
					.foregroundColor(.green)
				Text("Message Sent!")
					.font(.headline)
					.foregroundColor(Color(.label))
			}
			.padding(EdgeInsets(top: 20, leading: 25, bottom: 20, trailing: 25))
			.background(Material.regularMaterial)
			.cornerRadius(15)
			.shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
			.transition(.asymmetric(insertion: .scale(scale: 0.8, anchor: .center).combined(with: .opacity),
											removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .center))))
			.zIndex(1)
		}
	}
	
	// MARK: - Sheet and Alert Content Closures
	// ... (These remain unchanged) ...
	@ViewBuilder
	private func messageSettingsSheet() -> some View {
		MessageSettingsView(locationManager: self.locationManager)
	}
	
	@ViewBuilder
	private func contactPickerSheet() -> some View {
		NewContactPickerView { name, phoneNumber in
			guard let contactName = name, let contactPhoneNumber = phoneNumber else {
				self.addPartnerAlertMessage = "Could not retrieve complete contact details. Please ensure the contact has a name and phone number, then try again."
				self.showingAddPartnerErrorAlert = true
				return
			}
			
			let errorResult = viewModel.addTrustPartner(name: contactName, phoneNumber: contactPhoneNumber)
			
			if let actualError = errorResult {
				self.addPartnerAlertMessage = actualError.localizedDescription
				self.showingAddPartnerErrorAlert = true
			} else {
				let haptic = UIImpactFeedbackGenerator(style: .soft)
				haptic.impactOccurred()
			}
		}
	}
	
	@ViewBuilder
	private func messageComposerSheet() -> some View {
		let currentPrimaryInSheet = viewModel.primaryPartner
		if let partner = currentPrimaryInSheet {
			MessageComposeView(recipients: [partner.phoneNumber], body: messageBody) { result in
				showingMessageComposer = false
				
				switch result {
					case .sent:
						print("Message sent successfully by user.")
						let haptic = UINotificationFeedbackGenerator()
						haptic.notificationOccurred(.success)
						
						withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
							showMessageSentConfirmation = true
						}
						
						messageSentConfirmationDisappearTask?.cancel()
						
						let task = DispatchWorkItem {
							withAnimation(.easeOut(duration: 0.4)) {
								showMessageSentConfirmation = false
							}
						}
						messageSentConfirmationDisappearTask = task
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: task)
						
					case .cancelled:
						print("Message cancelled by user.")
					case .failed:
						print("Message failed to send.")
						let haptic = UINotificationFeedbackGenerator()
						haptic.notificationOccurred(.error)
					@unknown default:
						print("Message composer finished with an unknown state.")
				}
			}
		} else {
			Group {
				Text("Error: No recipient available to send message.").padding()
					.onAppear { DispatchQueue.main.async {
						self.showingMessageComposer = false }
					}
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
	// ... (Lifecycle and prepareAndSendMessage methods remain unchanged) ...
	private func onViewAppearLogic() {
		if !hasShownWelcomeAlert {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				showingWelcomeAlert = true
				hasShownWelcomeAlert = true
			}
		}
		
		if locationManager.authorizationStatus == .notDetermined {
			print("EmergencyContactView: Location status .notDetermined on appear, requesting permission.")
			locationManager.requestLocationPermission()
		} else {
			print("EmergencyContactView: Location status is \(locationManager.authorizationStatus.rawValue) on appear.")
		}
	}
	
	func prepareAndSendMessage() async {
		// ... (prepareAndSendMessage method remains unchanged) ...
		@AppStorage("useCustomEmergencyMessage_v1") var useCustomMessage: Bool = false
		@AppStorage("customEmergencyMessageText_v1") var customMessageText: String = "I'm using a custom message and need help. Please contact me."
		@AppStorage("includeLocationInMessage_v1") var includeLocationInSettings: Bool = true
		
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
		let currentStatus = locationManager.authorizationStatus
		
		if (currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways) && includeLocationInSettings {
			do {
				let timeoutDuration: TimeInterval = 10
				let fetchedLocationOptional: CLLocation? = try await
				withThrowingTaskGroup(of: CLLocation?.self, returning: CLLocation?.self) { group in
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
			} catch LocationError.permissionDenied {
				finalMessageBody += "\n\n(Location permission denied unexpectedly during fetch. Please check Settings.)"
			} catch LocationError.timeout {
				finalMessageBody += "\n\n(Could not retrieve location: timed out.)"
			} catch let otherError {
				finalMessageBody += "\n\n(Location services error: \(otherError.localizedDescription).)"
			}
		} else if !includeLocationInSettings {
			finalMessageBody += "\n\n(Location sharing turned off by user in settings.)"
			print("prepareAndSendMessage: Location sharing turned off by user setting.")
		} else if currentStatus == .denied || currentStatus == .restricted {
			finalMessageBody += "\n\n(Location services disabled or restricted for this app.)"
		} else if currentStatus == .notDetermined {
			finalMessageBody += "\n\n(Location permission not yet determined. Please try again or check Settings.)"
		}
		
		self.messageBody = finalMessageBody
		
		if MFMessageComposeViewController.canSendText() {
			showingMessageComposer = true
		} else {
			print("Device cannot send text messages.")
			self.addPartnerAlertMessage = "This device is not configured to send text messages. Please check your device settings."
			self.showingAddPartnerErrorAlert = true
		}
		isPreparingMessage = false
	}
}

#Preview {
	EmergencyContactView()
}
