//
//  NewContactPickerView.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/19.
//

// File: NewContactPickerView.swift

import SwiftUI
import ContactsUI // For CNContactPickerViewController

struct NewContactPickerView: UIViewControllerRepresentable {
	// Callback to return the picked contact's details
	// (String? for name, String? for phone number)
	var onContactPicked: (_ name: String?, _ phoneNumber: String?) -> Void
	
	// Environment variable to dismiss the sheet presentation
	@Environment(\.presentationMode) var presentationMode
	
	// Creates the UIKit view controller
	func makeUIViewController(context: Context) -> CNContactPickerViewController {
		let picker = CNContactPickerViewController()
		picker.delegate = context.coordinator // Set the delegate
		
		// Predicate to ensure only contacts with phone numbers are shown/selectable
		picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
		
		// We don't set 'displayedPropertyKeys'. This means when a contact is tapped,
		// the 'contactPicker(_:didSelect contact:)' delegate method will be called,
		// giving us the whole CNContact object.
		
		return picker
	}
	
	// Updates the view controller (not needed for this simple picker)
	func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
		// No specific updates needed when the SwiftUI view state changes.
	}
	
	// Creates the coordinator to act as the delegate
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	// Coordinator class to handle delegate callbacks from CNContactPickerViewController
	class Coordinator: NSObject, CNContactPickerDelegate {
		var parent: NewContactPickerView
		
		init(_ parent: NewContactPickerView) {
			self.parent = parent
		}
		
		// Delegate method called when a contact is selected
		func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
			// Extract the full name of the contact
			let name = CNContactFormatter.string(from: contact, style: .fullName)
			
			// Extract the first phone number.
			// For simplicity, we take the first one.
			// A more advanced implementation might let the user choose if multiple exist.
			let phoneNumber = contact.phoneNumbers.first?.value.stringValue
			
			// Call the completion handler with the extracted details
			parent.onContactPicked(name, phoneNumber)
			
			// Dismiss the contact picker sheet
			parent.presentationMode.wrappedValue.dismiss()
		}
		
		// Delegate method called when the user cancels the picker
		func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
			// Optionally, you could call the completion handler with nils
			// parent.onContactPicked(nil, nil)
			
			// Dismiss the contact picker sheet
			parent.presentationMode.wrappedValue.dismiss()
		}
	}
}

// Preview for NewContactPickerView
#Preview {
	// Since this view is typically presented in a sheet,
	// the preview will just show that it can be instantiated.
	// To truly test it, you'd need a button in the preview to present it.
	struct PreviewWrapper: View {
		@State var showPicker = false
		@State var pickedName: String?
		@State var pickedPhone: String?
		
		var body: some View {
			VStack {
				Text("Picked Name: \(pickedName ?? "None")")
				Text("Picked Phone: \(pickedPhone ?? "None")")
				Button("Show Contact Picker (Conceptual for Preview)") {
					// In a real app, this button would be in the parent view
					// and would toggle a @State variable bound to .sheet's isPresented.
					// For preview, clicking this won't do much unless we also
					// implement the sheet presentation here.
					showPicker = true
				}
			}
			.sheet(isPresented: $showPicker) {
				NewContactPickerView { name, phone in
					self.pickedName = name
					self.pickedPhone = phone
					// self.showPicker = false // The picker dismisses itself via presentationMode
				}
			}
			.onAppear {
				// You can also just test instantiation for preview
				// let _ = NewContactPickerView { _, _ in }
			}
		}
	}
	return PreviewWrapper()
}
