//
//  PulsatingGlowEffect.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/19.
//

// File: PulsatingGlowEffect.swift

// File: PulsatingGlowEffect.swift

import SwiftUI

struct PulsatingGlowEffect: ViewModifier {
	@State private var animateGlow: Bool = false // Use this to drive the animation directly
	
	let isEnabled: Bool
	let glowColor: Color
	let animationDuration: Double
	let minRadius: CGFloat
	let maxRadius: CGFloat
	
	init(isEnabled: Bool,
		  glowColor: Color = .red,
		  animationDuration: Double = 1.5,
		  minRadius: CGFloat = 1,
		  maxRadius: CGFloat = 12) {
		self.isEnabled = isEnabled
		self.glowColor = glowColor
		self.animationDuration = animationDuration
		self.minRadius = minRadius
		self.maxRadius = maxRadius
		// If enabled on init, immediately set state to start animation
		// _animateGlow = State(initialValue: isEnabled) // This might be too soon
	}
	
	func body(content: Content) -> some View {
		content
			.shadow(
				color: isEnabled ? glowColor.opacity(0.7) : .clear,
				// The radius changes based on 'animateGlow' when 'isEnabled'
				radius: isEnabled ? (animateGlow ? maxRadius : minRadius) : 0, // Use 0 if not enabled
				x: 0, y: 0
			)
			.onAppear {
				// Important: Set initial state for animation correctly
				if isEnabled {
					// Use a slight delay for onAppear to ensure view is ready
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
						if self.isEnabled { // Re-check, state might have changed
							self.animateGlow = true
						}
					}
				} else {
					self.animateGlow = false
				}
			}
			.onChange(of: isEnabled) { newIsEnabledValue in
				if newIsEnabledValue {
					// When enabling, start the animation cycle
					// A brief reset ensures the animation value changes
					self.animateGlow = false // Force a change
					DispatchQueue.main.async { // Allow UI to update
						self.animateGlow = true
					}
				} else {
					// When disabling, stop the animation
					self.animateGlow = false
				}
			}
		// The animation modifier watches 'animateGlow' (and implicitly 'isEnabled' due to conditional logic)
			.animation(
				isEnabled ?
				Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true) :
						.default, // No animation when disabled, or a quick fade out
				value: animateGlow // This is the value SwiftUI watches for changes to animate
			)
	}
}

// Extension remains the same
extension View {
	func pulsatingGlow(
		isEnabled: Bool,
		glowColor: Color = .red,
		animationDuration: Double = 1.5,
		minRadius: CGFloat = 1,
		maxRadius: CGFloat = 12
	) -> some View {
		self.modifier(PulsatingGlowEffect(
			isEnabled: isEnabled,
			glowColor: glowColor,
			animationDuration: animationDuration,
			minRadius: minRadius,
			maxRadius: maxRadius
		))
	}
}
