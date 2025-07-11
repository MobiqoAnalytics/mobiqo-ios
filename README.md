# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.9]
### Added
- SPM support

## [0.0.8]

### Added
- Added `includeAdvancedAnalysis` parameter to `syncUser()` method
- Added `includeAdvancedAnalysis` parameter to `getUserInfo()` method
- Enhanced API requests to support advanced analysis options (purchase probability and other data)

### Changed
- **BREAKING CHANGE**: Renamed `purchaseProbability` to `purchaseIntent` in Statistics struct
- Updated method signatures for `syncUser()` and `getUserInfo()` to include optional advanced analysis parameter
- Improved documentation with Swift examples of advanced analysis usage

## [0.0.7]

### Added
- Added `PURCHASE_FAILED` EventType
- Now supports getUserInfo method

## [0.0.6]

### Changed
- **BREAKING CHANGE**: Renamed `EventType` enum cases to match new naming convention
- Updated all usage examples and documentation
- Improved Swift API design and consistency

### Migration Guide
If you're upgrading from a previous version, update your event type usage:

```swift
// Before
Mobiqo.shared.trackEvent("button_pressed", eventType: .click)

// After  
Mobiqo.shared.trackEvent(event: "button_pressed", eventType: .click)
```

## [0.0.5]

### Added
- Initial release of Mobiqo iOS SDK
- User identification and session tracking with `syncUser()` method
- Custom event tracking with `trackEvent()` method
- Automatic heartbeat for session management (every 30 seconds)
- User analytics and predictions retrieval with `getUserInfo()` method
- Support for additional metadata in user sync and event tracking
- Comprehensive data models for user information and statistics
- Built-in error handling and logging
- UserDefaults integration for session persistence

### Features
- **User Management**: Sync users with RevenueCat IDs and additional metadata
- **Event Tracking**: Track user interactions with predefined event types
- **Session Management**: Automatic session tracking with heartbeat functionality
- **Analytics**: Retrieve user statistics including purchase probability, LTV, and ARPU
- **Error Handling**: Graceful error handling with informative logging

### Dependencies
- iOS 11.0+
- Swift 5.0+ 