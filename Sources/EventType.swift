// mobiqo-ios/Sources/EventType.swift

/// Represents the type of event being tracked by the Mobiqo SDK.
///
/// These predefined event types are used to categorize user interactions and behaviors,
/// aiding in analytics reporting and filtering within the Mobiqo dashboard.
public enum EventType: String, Codable {
    /// Indicates a user tapped or clicked on a button or UI element.
    case click
    /// Signifies a general user action that doesn't fit other specific types.
    case action
    /// Tracks when a new screen or page is displayed to the user.
    case screenView = "screen_view"
    /// Records when a paywall or subscription screen is presented to the user.
    case paywallView = "paywall_view"
    /// Tracks when a user closes or dismisses a paywall.
    case paywallDismiss = "paywall_dismiss"
    /// Signifies that a user has initiated a purchase flow.
    case purchaseAttempt = "purchase_attempt"
    /// Records a successful in-app purchase.
    /// Note: This is typically used if not relying on a RevenueCat webhook or similar server-side purchase validation.
    case purchaseSuccess = "purchase_success"
    /// Records a failed in-app purchase.
    case purchaseFailed = "purchase_failed"
    /// Tracks the submission of a form or input field.
    case formSubmit = "form_submit"
    /// Records user navigation between different screens or sections of the app.
    case navigation
    /// Indicates that a handled error or notable issue occurred within the application.
    case error
    /// Allows for a custom event type, for scenarios not covered by predefined types.
    /// Use the `properties` parameter in `trackEvent` to provide specifics.
    case custom
}
