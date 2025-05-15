//
//  MessageComposeView.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/16.
//

import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
	let recipients: [String]
	let body: String
	let completion: (MessageComposeResult) -> Void
	
	@Environment(\.presentationMode) var presentationMode
	
	func makeUIViewController(context: Context) -> MFMessageComposeViewController {
		let controller = MFMessageComposeViewController()
		// It's good practice to check if the device can send text before configuring.
		// However, in a preview, this might always be false.
		// For the preview to not crash if it somehow tried to present,
		// we might only configure if it can send text.
		// But for just instantiating the struct for preview, this is less critical.
		if MFMessageComposeViewController.canSendText() {
			controller.messageComposeDelegate = context.coordinator
			controller.recipients = recipients
			controller.body = body
		} else {
			// In a real app, you'd handle this (e.g., show an alert).
			// In a preview, this controller might not even be properly displayable.
			print("Preview: Device cannot send text messages. MessageComposeView might not display correctly.")
		}
		return controller
	}
	
	func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
		// No update needed, or you could re-apply recipients/body if they could change
		// and the view was being reused, but for a sheet presentation, it's usually new.
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
		var parent: MessageComposeView
		
		init(_ parent: MessageComposeView) {
			self.parent = parent
		}
		
		func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
			parent.completion(result)
			// The sheet presentation (from the parent view) will handle dismissal.
		}
	}
}

#Preview {
	// Provide dummy data for the preview
	MessageComposeView(
		recipients: ["1234567890"], // Dummy recipient
		body: "This is a test message for the preview.", // Dummy body
		completion: { result in // Dummy completion handler
			print("MessageComposeView preview completion: \(result)")
		}
	)
	// Add a .frame to give it some size in the preview canvas, though it might not show much.
	// .frame(width: 300, height: 500)
	// .previewDisplayName("Message Composer (Limited)")
}
