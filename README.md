# Mobiqo iOS SDK

**⚠️ THIS SDK HAS TO BE USED ALONG WITH THE ANALYTICS SERVICE MOBIQO ⚠️**

**👉 CREATE AN ACCOUNT HERE: https://getmobiqo.com?utm_source=github**

---

A native iOS SDK for integrating Mobiqo analytics into your iOS applications.

## Installation

### CocoaPods

Mobiqo is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'Mobiqo'
```

Then, run `pod install`.

### Swift Package Manager

You can also install Mobiqo using Swift Package Manager by adding the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MobiqoAnalytics/mobiqo-ios.git", from: "0.0.10")
]
```

## Usage

### Import the SDK

```swift
import Mobiqo
```

### Initialize the SDK

Initialize the SDK in your `AppDelegate.swift` or `SceneDelegate.swift`:

```swift
// In AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Initialize with your Mobiqo API key
    Mobiqo.shared.initialize(mobiqoKey: "your-mobiqo-api-key") { success, error in
        if success {
            print("Mobiqo initialized successfully")
        } else {
            print("Mobiqo initialization failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    return true
}
```

### Sync user data

```swift
// With additional data (optional)
Mobiqo.shared.syncUser(
    revenueCatUserId: "user-123",
    includeAdvancedAnalysis: false,
    additionalData: [
        "email": "user@example.com",
        "plan": "premium"
    ]
) { result in
    switch result {
    case .success(let response):
        print("User synced successfully")
        print("Is new user: \(response.isNewUser)")
        print("User OS: \(response.appUser.os)")
        print("Purchase intent: \(response.statistics.purchaseIntent)")
    case .failure(let error):
        print("Failed to sync user: \(error.localizedDescription)")
    }
}

// Without additional data
Mobiqo.shared.syncUser(revenueCatUserId: "user-123") { result in
    // Handle result
}
```

### Track events

```swift
// Track an event with additional data (optional)
Mobiqo.shared.trackEvent(
    event: "button_clicked",
    eventType: .click,
    additionalData: [
        "button_name": "subscribe",
        "screen": "home"
    ]
) { success, error in
    if success {
        print("Event tracked successfully")
    } else {
        print("Failed to track event: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// Track an event without additional data
Mobiqo.shared.trackEvent(
    event: "screen_opened",
    eventType: .screenView
) { success, error in
    // Handle result
}
```

### Get user information

```swift
Mobiqo.shared.getUserInfo(
    revenueCatUserId: "user-123",
    includeAdvancedAnalysis: true
) { result in
    switch result {
    case .success(let userInfo):
        print("User info retrieved successfully")
        print("Purchase intent: \(userInfo.statistics.purchaseIntent)")
        print("User country: \(userInfo.appUser.country ?? "Unknown")")
    case .failure(let error):
        print("Failed to get user info: \(error.localizedDescription)")
    }
}
```

### Automatic Session Tracking

The SDK automatically sends heartbeats every 20 seconds after user sync to maintain session tracking. No manual intervention is required.

## API Reference

### Methods

#### `initialize(mobiqoKey:completion:)`
Initialize the Mobiqo service with your API key.
- `mobiqoKey` (String): Your Mobiqo API key
- `completion` (Optional closure): Called with success/failure result

#### `syncUser(revenueCatUserId:includeAdvancedAnalysis:additionalData:completion:)`
Sync user data with Mobiqo and start a session.
- `revenueCatUserId` (String): RevenueCat user ID
- `includeAdvancedAnalysis` (Bool, optional): whether or not to include advanced analysis in the response (to get the purchase probability and other data, but the request will take more time)
- `additionalData` ([String: Any], optional): Additional user data
- `completion` (Optional closure): Called with `Result<SyncUserResponse, Error>`

#### `getUserInfo(revenueCatUserId:includeAdvancedAnalysis:completion:)`
Retrieve user information from Mobiqo.
- `revenueCatUserId` (String): RevenueCat user ID
- `includeAdvancedAnalysis` (Bool, optional): whether or not to include advanced analysis in the response (to get the purchase probability and other data, but the request will take more time)
- `completion` (Closure): Called with `Result<GetUserInfoResponse, Error>`

#### `trackEvent(event:eventType:additionalData:completion:)`
Track custom events.
- `event` (String): Event name
- `eventType` (EventType): Event type from the EventType enum
- `additionalData` ([String: Any], optional): Additional event data
- `completion` (Optional closure): Called with success/failure result

#### `dispose()`
Clean up the SDK and stop heartbeat tracking.

### Event Types

```swift
public enum EventType: String, Codable {
    case click = "click"
    case action = "action"
    case screenView = "screen_view"
    case paywallView = "paywall_view"
    case paywallDismiss = "paywall_dismiss"
    case purchaseAttempt = "purchase_attempt"
    case purchaseSuccess = "purchase_success"
    const purchaseFailed = "purchase_failed"
    case formSubmit = "form_submit"
    case navigation = "navigation"
    case error = "error"
    case custom = "custom"
}
```

### Response Models

#### `SyncUserResponse`
```swift
public struct SyncUserResponse: Codable {
    public let isNewUser: Bool
    public let appUser: AppUser
    public let statistics: Statistics
    public let sessionId: String
}
```

#### `GetUserInfoResponse`
```swift
public struct GetUserInfoResponse: Codable {
    public let appUser: AppUser
    public let statistics: Statistics
}
```

#### `AppUser`
```swift
public struct AppUser: Codable {
    public let id: String
    public let projectId: String
    public let revenueCatUserId: String?
    public let mobiqoUsername: String
    public let os: String
    public let osVersion: String
    public let appVersion: String
    public let country: String?
    public let language: String?
    public let firstSeenAt: String
    public let lastSeenAt: String
    public let activeEntitlements: [String]
}
```

#### `Statistics`
```swift
public struct Statistics: Codable {
    public let purchasingPowerParity: Double
    public let purchaseIntent: Double
    public let avgArpu: Double
    public let avgArppu: Double
    public let avgLtv: Double
}
```

### Error Handling

The SDK provides comprehensive error handling through the `MobiqoError` enum:

```swift
public enum MobiqoError: Error, LocalizedError {
    case sdkNotInitialized
    case sdkNotInitializedOrUserNotSynced
    case invalidUrl
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case encodingError(Error)
    case apiError(statusCode: Int, message: String)
    case initializationFailed(String)
}
```

## Advanced Usage

### Complete Integration Example

```swift
import UIKit
import Mobiqo

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Mobiqo
        Mobiqo.shared.initialize(mobiqoKey: "your-mobiqo-api-key") { success, error in
            if success {
                print("✅ Mobiqo initialized successfully")
                
                // Sync user after successful initialization
                self.syncCurrentUser()
            } else {
                print("❌ Mobiqo initialization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        return true
    }
    
    private func syncCurrentUser() {
        // Get user ID from RevenueCat
        let userId = getCurrentUserId() // Your method to get Revenue Cat user ID
        
        Mobiqo.shared.syncUser(
            revenueCatUserId: userId,
            additionalData: [
                "user_segment": "premium",
                "signup_date": "2024-01-01",
                "referral_source": "organic"
            ]
        ) { result in
            switch result {
            case .success(let response):
                print("✅ User synced: \(response.appUser.mobiqoUsername)")
                print("📊 Purchase intent: \(response.statistics.purchaseIntent)")
            case .failure(let error):
                print("❌ User sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCurrentUserId() -> String {
        // Return the current user's RevenueCat ID
        return "$RCAnonymousID:1234"
    }
}
```

### Tracking Events Throughout Your App

```swift
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Track screen view
        Mobiqo.shared.trackEvent(
            event: "home_screen_viewed",
            eventType: .screenView,
            additionalData: ["source": "main_navigation"]
        ) { success, error in
            if !success {
                print("Failed to track screen view: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    @IBAction func subscribeButtonTapped(_ sender: UIButton) {
        // Track button click
        Mobiqo.shared.trackEvent(
            event: "subscribe_button_clicked",
            eventType: .click,
            additionalData: [
                "button_location": "home_screen",
                "user_plan": "free"
            ]
        ) { success, error in
            if !success {
                print("Failed to track button click: \(error?.localizedDescription ?? "")")
            }
        }
        
        // Show paywall
        showPaywall()
    }
    
    private func showPaywall() {
        // Track paywall view
        Mobiqo.shared.trackEvent(
            event: "paywall_shown",
            eventType: .paywallView,
            additionalData: ["paywall_type": "premium_upsell"]
        )
    }
}
```

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## License

MIT

## Support

For support and questions, please contact the Mobiqo team or visit [getmobiqo.com](https://getmobiqo.com).
```
