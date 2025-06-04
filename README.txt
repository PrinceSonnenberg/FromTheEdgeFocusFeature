//
//
//  EmergencyFocus README
//
//  Created by Prince Ezra on 2025/06/02.
//

//
// encapsulates.swift
// EmergencyFocus
//
// Created by Prince Ezra on 2025/06/02.
// Updated: [Current Date, e.g., 2025/06/04]
//

This commit introduces the complete "Trust Partners" feature, enabling users to designate
trusted individuals for emergency notifications. It encompasses UI, data management, system
service integration, and significant UX enhancements for a more polished and engaging experience.

**Core Functionality:**

*   **Multi-Partner Management:**
    *   Allows users to add multiple Trust Partners from device contacts.
    *   Stores partner name and phone number persistently (UserDefaults via JSON).
    *   **Input Validation:** Validates South African mobile number formats before saving, providing user feedback for invalid or duplicate entries.
    *   Users can select one partner as "Active" for emergency actions.
    *   Provides UI to add, list, and set active partners.
    *   Supports swipe-to-delete for individual partners (with confirmation).
    *   Supports removing all partners (with confirmation).
*   **"Get Help" Action:**
    *   Prominent "Get Help" button triggers an SMS to the active Trust Partner.
    *   Button state (enabled/disabled, color, shadow) reflects active partner status and message preparation state.
    *   Haptic feedback on button press.
*   **Emergency Message System:**
    *   Integrates with `MFMessageComposeViewController` for user-initiated SMS.
    *   Message content includes either a default template or a user-customized message.
    *   Placeholders (e.g., `{NAME}`) are replaced with active partner's details.
*   **Location Integration:**
    *   Optionally appends user's current location to the emergency SMS.
    *   Uses `CoreLocation` for fetching location with `async/await`.
    *   Includes a timeout for location requests.
    *   Handles location permission states gracefully.

**User Experience & UI Enhancements:**

*   **Dedicated Settings Screen (`MessageSettingsView`):**
    *   Users can toggle between default and custom emergency messages.
    *   Provides a `TextEditor` for custom message input.
    *   Users can toggle on/off the inclusion of location data in messages (defaults to on).
    *   Settings UI adapts based on app-level location permission status.
    *   **Animated Presentation:** Sheet content animates in with a spring effect for a smoother appearance.
*   **Location Permission Handling:**
    *   `LocationPermissionNoticeView` informs users if location access is denied or restricted and provides a shortcut to app settings.
    *   **Animated Banner:** Permission notice banner slides in/out smoothly with haptic feedback (.warning).
    *   Initial permission request handled in `onAppear` if status is not determined.
*   **Animations & Feedback:**
    *   **CTA Enhancements:**
        *   "Get Help" button jiggles periodically when disabled due to no active partner.
        *   "Get Help" button has a pulsating glow effect when enabled and active.
        *   "Get Help" button now has a subtle shadow for better visual hierarchy.
    *   **View Transitions:**
        *   Smooth, animated transitions (slide and fade) between the empty state and the partners list.
        *   `ProgressView` (for message preparation) fades in/out smoothly.
        *   Primary partner selection in the list animates the change of checkmarks/buttons.
    *   **Haptic Feedback:**
        *   On "Get Help" button tap.
        *   On successful addition of a new Trust Partner.
        *   On message send success/failure via `MFMessageComposeViewController`.
        *   When the location permission banner appears due to a denied/restricted status.
    *   **Visual Confirmation:**
        *   A "Message Sent!" overlay with a green checkmark briefly appears after successfully sending a message.
*   **Onboarding:**
    *   A one-time welcome alert explains the Trust Partners screen on first use.
*   **Layout & Styling:**
    *   **Card-Style Partner List:** Trust Partner rows are now displayed as distinct cards with improved visual separation and touch ergonomics.
    *   **Improved Empty State:** The view for when no partners are added now includes a relevant icon and refined text hierarchy for better visual appeal.
    *   **Refined Spacing:** Adjustments made to vertical spacing for a more consistent rhythm.
    *   **Typography:** Section headers are styled for clarity.
*   **Modular Design:**
    *   `TrustPartnerViewModel` manages data and business logic.
    *   Reusable SwiftUI components created: `PartnerRow` (now card-styled), `LocationPermissionNoticeView`, `EmptyStateViewContent`.
    *   Reusable `ViewModifier`s created: `JiggleEffect`, `PulsatingGlowEffect`.
    *   `UIViewControllerRepresentable` wrappers for `CNContactPickerViewController` (`NewContactPickerView`) and `MFMessageComposeViewController` (`MessageComposeView`).

**Technical Details:**

*   Built with SwiftUI, targeting iOS 15.6+ (with considerations for API compatibility).
*   Uses `@AppStorage` for simple preferences and `UserDefaults` with `JSONEncoder`/`Decoder` for storing the `TrustPartner` array.
*   Employs `async/await` for modern concurrency in location fetching and message preparation.
*   `LocationManager` class encapsulates `CoreLocation` interactions.

This feature provides a robust and user-friendly way for individuals to quickly reach out to their
support network in times of need, now with an even more polished and engaging user interface.
