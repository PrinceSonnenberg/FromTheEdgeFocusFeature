//
//  LocationManager.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/16.
//

// File: LocationManager.swift

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	private let manager = CLLocationManager()
	@Published var authorizationStatus: CLAuthorizationStatus
	
	// We still keep lastKnownLocation if other parts of the app might observe it,
	// but for the specific Get Help action, we'll use the async fetch.
	@Published var lastKnownLocation: CLLocation?
	
	private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
	
	override init() {
		authorizationStatus = manager.authorizationStatus
		super.init()
		manager.delegate = self
		manager.desiredAccuracy = kCLLocationAccuracyBest // Or kCLLocationAccuracyNearestTenMeters
	}
	
	func requestLocationPermission() {
		if authorizationStatus == .notDetermined {
			print("Requesting location permission.")
			manager.requestWhenInUseAuthorization()
		} else {
			print("Location permission status: \(authorizationStatus.rawValue)")
		}
	}
	
	// Async function to get a single location update
	func fetchCurrentLocation() async throws -> CLLocation? {
		print("LocationManager: fetchCurrentLocation called.")
		// Ensure permissions are requested if not determined.
		// The actual location request will only proceed if authorized.
		if authorizationStatus == .notDetermined {
			requestLocationPermission()
			// Give a moment for the permission dialog to potentially be actioned.
			// A more robust solution might involve observing authorizationStatus changes.
			// For now, if it was .notDetermined, we'll proceed, and CLLocationManager
			// itself won't return a location if not authorized.
		}
		
		// Check current authorization status before proceeding
		guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
			print("LocationManager: Permission not granted (\(authorizationStatus.rawValue)). Throwing error.")
			throw LocationError.permissionDenied // Or notYetDetermined
		}
		
		print("LocationManager: Permission granted. Proceeding to request location via continuation.")
		return try await withCheckedThrowingContinuation { continuation in
			self.locationContinuation = continuation
			manager.requestLocation() // Request a single location update
		}
	}
	
	// MARK: - CLLocationManagerDelegate Methods
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let newLocation = locations.first
		self.lastKnownLocation = newLocation // Update published property
		
		print("LocationManager: didUpdateLocations - \(String(describing: newLocation))")
		if let continuation = self.locationContinuation {
			print("LocationManager: Resuming continuation with location.")
			continuation.resume(returning: newLocation)
			self.locationContinuation = nil // Important: Reset for next request
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("LocationManager: didFailWithError - \(error.localizedDescription)")
		if let continuation = self.locationContinuation {
			print("LocationManager: Resuming continuation with error.")
			continuation.resume(throwing: error)
			self.locationContinuation = nil // Important: Reset for next request
		}
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		let oldStatus = authorizationStatus
		authorizationStatus = manager.authorizationStatus // Update published property
		print("LocationManager: locationManagerDidChangeAuthorization from \(oldStatus.rawValue) to \(authorizationStatus.rawValue)")
		
		// If a continuation was pending due to .notDetermined and permission is now granted,
		// it might be necessary to re-trigger manager.requestLocation() if the initial one didn't fire.
		// However, the `fetchCurrentLocation`'s guard should handle this.
		// If permission was granted AND a continuation exists, it implies requestLocation was already called.
	}
}

enum LocationError: Error, LocalizedError {
	case permissionDenied
	case permissionNotYetDetermined // Could be a specific state
	case timeout
	case unknown
	
	var errorDescription: String? {
		switch self {
			case .permissionDenied:
				return "Location permission was denied. Please enable it in Settings."
			case .permissionNotYetDetermined:
				return "Location permission has not been determined yet."
			case .timeout:
				return "Getting location timed out."
			case .unknown:
				return "An unknown error occurred while fetching location."
		}
	}
}
