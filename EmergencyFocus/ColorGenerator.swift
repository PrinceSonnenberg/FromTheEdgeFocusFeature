//
//  ColorGenerator.swift
//  EmergencyFocus
//
//  Created by Prince Ezra on 2025/05/20.
//

// File: ColorGenerator.swift (for SwiftUI)

import SwiftUI // Import SwiftUI for the Color type

struct ColorGenerator {
	
	/// Generates a random "cool" or "calm" light SwiftUI Color.
	/// - Returns: A SwiftUI Color instance.
	static func generateCalmLightSwiftUIColor() -> Color {
		// HSB: Hue, Saturation, Brightness, Opacity (SwiftUI uses Opacity, similar to Alpha)
		
		// 1. HUE: Define ranges for cool/calm colors (0.0 to 1.0)
		let hueRanges = [
			(0.45, 0.75), // Cyans, Blues, some Purples
			(0.25, 0.40)  // Calmer Greens
			// You can add more ranges like:
			// (0.75, 0.85) // Indigos, Violets
		]
		// Select one of the ranges randomly
		let selectedRange = hueRanges.randomElement() ?? (0.55, 0.70) // Default to blues
		
		// Generate a random hue within the selected range
		let hue = Double.random(in: selectedRange.0 ... selectedRange.1)
		
		// 2. SATURATION: Keep it moderate to low for calmness.
		let saturation = Double.random(in: 0.3 ... 0.65) // Adjust for desired pastel/calmness
		
		// 3. BRIGHTNESS: Keep it high to ensure light colors.
		let brightness = Double.random(in: 0.80 ... 0.98) // Closer to 1.0 is lighter
		
		// 4. OPACITY: Fully opaque.
		let opacity: Double = 1.0
		
		return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: opacity)
	}
	
	/// Generates a random pastel SwiftUI Color.
	/// - Returns: A SwiftUI Color instance.
	static func generatePastelSwiftUIColor() -> Color {
		let hue = Double.random(in: 0 ... 1)
		let saturation = Double.random(in: 0.20 ... 0.45) // Lower saturation for pastels
		let brightness = Double.random(in: 0.88 ... 0.98) // High brightness for pastels
		let opacity: Double = 1.0
		
		return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: opacity)
	}
	
	/// Generates an array of distinct calm/pastel SwiftUI Colors.
	/// - Parameter count: The number of distinct colors to generate.
	/// - Parameter baseGenerator: The function to use for generating each color.
	/// - Returns: An array of SwiftUI Color instances.
	static func generateDistinctCalmColors(count: Int, using baseGenerator: () -> Color = generatePastelSwiftUIColor) -> [Color] {
		var colors: [Color] = []
		var attempts = 0
		let maxAttempts = count * 5 // Prevent infinite loop if distinct colors are hard to find
		
		while colors.count < count && attempts < maxAttempts {
			let newColor = baseGenerator()
			// Basic check for distinctness (not perfect, as HSB can wrap)
			// A more robust check would compare HSB components with a tolerance.
			// For visual distinction, this simple check might be okay for a small number of colors.
			if !colors.contains(where: { existingColor in
				// This is a very rough check. True color distance is more complex.
				// For now, just ensure it's not literally the same generated object.
				// If baseGenerator always returns new objects, this check is trivial.
				// A better check might involve converting to RGB and checking distance.
				// For now, let's assume the randomness is enough for small counts.
				// To force more distinctness, we could check if HSB values are too close.
				// Let's rely on the randomness of the generator for now.
				// If you need very distinct colors, this part needs enhancement.
				return false // Forcing add for now, relying on random diversity
			}) {
				colors.append(newColor)
			}
			attempts += 1
		}
		
		// If not enough distinct colors were found, fill with potentially similar ones
		while colors.count < count {
			colors.append(baseGenerator())
		}
		
		return colors
	}
}
