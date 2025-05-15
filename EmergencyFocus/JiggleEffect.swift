//
//  JiggleEffect.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/19.
//

// File: JiggleEffect.swift - RADICAL SIMPLIFICATION FOR DEBUGGING

import SwiftUI

struct JiggleEffect: ViewModifier {
	@State private var jiggleAngle: Angle = .degrees(0)
	@State private var jiggleTimer: Timer?
	
	let isEnabledInput: Bool // Value from parent
	let timeInterval: TimeInterval
	let jiggleDegrees: Double
	
	@State private var previousIsEnabledInput: Bool
	// @State private var timerShouldBeActive: Bool // Removing this for the test
	
	init(isEnabled: Bool, timeInterval: TimeInterval = 3.0, jiggleDegrees: Double = 2.5) {
		self.isEnabledInput = isEnabled
		self.timeInterval = timeInterval
		self.jiggleDegrees = jiggleDegrees
		_previousIsEnabledInput = State(initialValue: isEnabled)
		// _timerShouldBeActive = State(initialValue: isEnabled) // Removed
		print("JiggleEffect: init with isEnabledInput: \(isEnabled)")
	}
	
	func body(content: Content) -> some View {
		content
			.rotationEffect(jiggleAngle)
			.onAppear {
				print("JiggleEffect (iOS 15): .onAppear, isEnabledInput: \(isEnabledInput)")
				previousIsEnabledInput = isEnabledInput
				if isEnabledInput { // Start based on initial input
					print("JiggleEffect (iOS 15): .onAppear - Starting timer.")
					startJiggleTimer()
				}
			}
			.onDisappear {
				print("JiggleEffect (iOS 15): .onDisappear, stopping timer.")
				stopJiggleTimer()
			}
			.onChange(of: isEnabledInput) { newIsEnabledInputValue in
				print("JiggleEffect (iOS 15): .onChange(of: isEnabledInput) called. New: \(newIsEnabledInputValue), Previous: \(previousIsEnabledInput)")
				if newIsEnabledInputValue != previousIsEnabledInput {
					if newIsEnabledInputValue {
						print("JiggleEffect (iOS 15): onChange - isEnabledInput is now TRUE. Starting timer.")
						startJiggleTimer()
					} else {
						print("JiggleEffect (iOS 15): onChange - isEnabledInput is now FALSE. Stopping timer.")
						stopJiggleTimer()
						withAnimation(.easeOut(duration: 0.2)) {
							jiggleAngle = .degrees(0)
						}
					}
				}
				previousIsEnabledInput = newIsEnabledInputValue
			}
	}
	
	private func triggerJiggle() {
		// NO GUARD HERE FOR THIS TEST - if timer fires, it jiggles.
		// We rely on stopJiggleTimer being called correctly.
		print("JiggleEffect (iOS 15): triggerJiggle() - Executing jiggle animation sequence. (No internal guard)")
		let animationDuration = 0.1
		// ... (jiggle animation sequence as before) ...
		withAnimation(.easeInOut(duration: animationDuration)) { jiggleAngle = .degrees(jiggleDegrees) }
		DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
			withAnimation(.easeInOut(duration: animationDuration)) { jiggleAngle = .degrees(-jiggleDegrees) }
			DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
				withAnimation(.easeInOut(duration: animationDuration)) { jiggleAngle = .degrees(jiggleDegrees / 2) }
				DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
					withAnimation(.easeInOut(duration: animationDuration * 0.8)) { jiggleAngle = .degrees(0) }
				}
			}
		}
	}
	
	private func startJiggleTimer() {
		stopJiggleTimer() // Always stop previous before starting new
		print("JiggleEffect (iOS 15): startJiggleTimer - Actually scheduling new timer. Interval: \(timeInterval)s")
		
		let newTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [self] _ in // Capture self
																																		 // The 'self' captured here is the instance of JiggleEffect that created the timer.
			print("JiggleEffect (iOS 15): Timer Fired. isEnabledInput for this instance: \(self.isEnabledInput)")
			self.triggerJiggle()
		}
		RunLoop.current.add(newTimer, forMode: .common)
		self.jiggleTimer = newTimer
	}
	
	private func stopJiggleTimer() {
		if jiggleTimer != nil {
			print("JiggleEffect (iOS 15): stopJiggleTimer() called, invalidating active timer.")
			jiggleTimer?.invalidate()
			jiggleTimer = nil
		}
	}
}

// Extension remains the same
extension View {
	func jiggle(isEnabled: Bool, timeInterval: TimeInterval = 3.0, degrees: Double = 2.5) -> some View {
		self.modifier(JiggleEffect(isEnabled: isEnabled, timeInterval: timeInterval, jiggleDegrees: degrees))
	}
}
