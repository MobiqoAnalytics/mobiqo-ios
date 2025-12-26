# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-06

### Added
- **MAJOR RELEASE**: First stable production release of Mobiqo iOS SDK
- Added `AdditionalData` struct for structured user data with fields:
  - `userId`: Optional user identifier
  - `userName`: Optional user display name
  - `userEmail`: Optional user email address
  - `referrer`: Optional referrer/source tracking
- Added `updateUser()` method to update user information without creating a new session
- Added `additionalData` parameter to `syncUser()` method for passing structured user data
- Enhanced API requests to include `personal_data` field with user information
- Comprehensive documentation for all public methods and structs

### Changed
- `syncUser()` now accepts typed `AdditionalData` parameter instead of generic `[String: Any]`
- `syncUser()` API request now includes `project_id` in the request body for consistency
- `updateUser()` API request includes `project_id` for proper server-side validation
- Improved type safety across all user-related operations
- Enhanced error handling in `updateUser()` method
- Updated README with detailed examples of new features and correct struct usage
- Updated Mobiqo.podspec and Package.swift version to 1.0.0

### Fixed
- Corrected code examples to use proper `AdditionalData` struct
- Fixed extra closing backtick in README
- Updated all examples to reflect actual struct structure

### Documentation
- Updated README with `updateUser()` method usage examples
- Added `AdditionalData` struct documentation to API Reference
- Corrected all examples to use proper field names matching the Swift structs
- Enhanced method documentation with clearer parameter descriptions

## [0.0.10]

### Added
- Added `group` attribute to `AppUser` struct for A/B testing support (values: 'red' or 'blue')
- Added device model tracking - now automatically captured using `uname` system call and sent with `syncUser()` requests
- Device model returns actual hardware identifier (e.g., "iPhone13,2", "iPhone14,5")

### Changed
- **PERFORMANCE IMPROVEMENT**: Heartbeat interval reduced from 30 seconds to 20 seconds for better session accuracy
- Updated `syncUser()` method to include device model in API requests

### Notes
- iOS SDK always returns actual hardware model - no additional dependencies needed

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