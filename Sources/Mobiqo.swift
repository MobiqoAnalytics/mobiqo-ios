// mobiqo-ios/Sources/Mobiqo.swift

import Foundation
import UIKit // For UIDevice

/// The primary class for interacting with the Mobiqo iOS SDK.
///
/// This singleton class provides methods to initialize the SDK, synchronize user data,
/// track events, retrieve user information, and manage the SDK's lifecycle.
public class Mobiqo {
    /// The shared singleton instance of the Mobiqo SDK.
    public static let shared = Mobiqo()

    /// The project ID for your Mobiqo project. Stored in UserDefaults.
    private var projectId: String?
    /// The session ID for the current user session. Stored in UserDefaults.
    private var sessionId: String?
    /// Timer used for periodic heartbeats.
    private var heartbeatTimer: Timer?
    /// Standard UserDefaults instance for persisting SDK data.
    private let userDefaults = UserDefaults.standard
    /// Base URL for the Mobiqo API - matches Capacitor SDK
    private let apiBaseUrl = "https://us-central1-mobiqo-582b4.cloudfunctions.net"

    /// Defines the keys used for storing Mobiqo SDK data in UserDefaults.
    private enum UserDefaultsKeys: String {
        /// Key for storing the project ID.
        case projectId = "mobiqo_project_id"
        /// Key for storing the session ID.
        case sessionId = "mobiqo_session_id"
    }

    /// Private initializer to enforce singleton pattern. Loads data from UserDefaults upon initialization.
    private init() {
        self.projectId = userDefaults.string(forKey: UserDefaultsKeys.projectId.rawValue)
        self.sessionId = userDefaults.string(forKey: UserDefaultsKeys.sessionId.rawValue)
    }

    /// Initializes the Mobiqo SDK with your API key.
    ///
    /// This method should be called once, typically when your application starts,
    /// usually in `application(_:didFinishLaunchingWithOptions:)`.
    /// It validates the credentials with the Mobiqo backend and prepares the SDK for use.
    ///
    /// - Parameters:
    ///   - mobiqoKey: Your unique API key for your Mobiqo project.
    ///   - completion: An optional closure called upon completion of the initialization.
    ///                 The closure receives a `Bool` indicating success or failure,
    ///                 and an optional `Error` if initialization failed.
    public func initialize(mobiqoKey: String, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        guard let url = URL(string: "\(apiBaseUrl)/init") else {
            completion?(false, MobiqoError.invalidUrl)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["mobiqoKey": mobiqoKey]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion?(false, MobiqoError.encodingError(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion?(false, MobiqoError.networkError(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion?(false, MobiqoError.invalidResponse)
                return
            }

            guard httpResponse.statusCode == 200 else {
                completion?(false, MobiqoError.apiError(statusCode: httpResponse.statusCode, message: "Initialization failed"))
                return
            }

            do {
                let initResponse = try JSONDecoder().decode(InitResponse.self, from: data)
                if initResponse.authorized {
                    self.projectId = initResponse.project.id
                    self.userDefaults.set(self.projectId, forKey: UserDefaultsKeys.projectId.rawValue)
                    completion?(true, nil)
                } else {
                    // Clear project ID if not authorized
                    self.userDefaults.removeObject(forKey: UserDefaultsKeys.projectId.rawValue)
                    completion?(false, MobiqoError.initializationFailed("Project not found or not authorized"))
                }
            } catch {
                completion?(false, MobiqoError.decodingError(error))
            }
        }.resume()
    }

    /// Synchronizes the current user's data with the Mobiqo backend and starts a tracking session.
    ///
    /// This method links a RevenueCat user ID with Mobiqo analytics and starts
    /// automatic heartbeat tracking (every 30 seconds). Call this after user login
    /// or when you want to start tracking a user's session.
    ///
    /// - Parameters:
    ///   - revenueCatUserId: The RevenueCat user identifier.
    ///   - additionalData: Optional extra user data to store (email, plan, etc.).
    ///   - completion: An optional closure called with the result of the synchronization.
    ///                 It receives a `Result` type containing either a `SyncUserResponse` on success
    ///                 or an `Error` on failure.
    public func syncUser(revenueCatUserId: String, additionalData: [String: Any]? = nil, completion: ((Result<SyncUserResponse, Error>) -> Void)? = nil) {
        guard let currentProjectId = projectId else {
            completion?(.failure(MobiqoError.sdkNotInitialized))
            return
        }

        guard let url = URL(string: "\(apiBaseUrl)/linkUser") else {
            completion?(.failure(MobiqoError.invalidUrl))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var requestBody: [String: Any] = [
            "revenue_cat_user_id": revenueCatUserId,
            "project_id": currentProjectId,
            "local_timestamp": Int(Date().timeIntervalSince1970 * 1000) // milliseconds
        ]
        
        if let additionalData = additionalData {
            requestBody["additional_data"] = additionalData
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion?(.failure(MobiqoError.encodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion?(.failure(MobiqoError.networkError(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion?(.failure(MobiqoError.invalidResponse))
                return
            }

            guard httpResponse.statusCode == 200 else {
                completion?(.failure(MobiqoError.apiError(statusCode: httpResponse.statusCode, message: "User sync failed. Raw response: \(String(data: data, encoding: .utf8) ?? "")")))
                return
            }

            do {
                let syncResponse = try JSONDecoder().decode(SyncUserResponse.self, from: data)
                // Store session ID from response
                self.sessionId = syncResponse.sessionId
                self.userDefaults.set(self.sessionId, forKey: UserDefaultsKeys.sessionId.rawValue)
                
                // Start heartbeat if not already running
                if self.heartbeatTimer == nil {
                    self.startHeartbeat()
                }
                
                completion?(.success(syncResponse))
            } catch {
                completion?(.failure(MobiqoError.decodingError(error)))
            }
        }.resume()
    }

    /// Tracks a custom event with Mobiqo analytics.
    ///
    /// Records user interactions, behaviors, and custom events for analytics.
    /// Events are automatically timestamped and associated with the current user session.
    ///
    /// - Parameters:
    ///   - event: Name/identifier for the event (e.g., 'button_clicked', 'screen_viewed').
    ///   - eventType: Type of event from EventType enum (CLICK, SCREEN_VIEW, etc.).
    ///   - additionalData: Optional custom data to attach to the event.
    ///   - completion: An optional closure called upon completion of the event tracking.
    ///                 It receives a `Bool` indicating success and an optional `Error`.
    public func trackEvent(event: String, eventType: EventType, additionalData: [String: Any]? = nil, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        guard let currentSessionId = sessionId else {
            completion?(false, MobiqoError.sdkNotInitializedOrUserNotSynced)
            return
        }

        guard let url = URL(string: "\(apiBaseUrl)/trackEvent") else {
            completion?(false, MobiqoError.invalidUrl)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var eventAdditionalData = additionalData ?? [:]
        eventAdditionalData["local_timestamp"] = Int(Date().timeIntervalSince1970 * 1000) // milliseconds

        let requestBody: [String: Any] = [
            "event_name": event,
            "event_type": eventType.rawValue,
            "session_id": currentSessionId,
            "additional_data": eventAdditionalData
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion?(false, MobiqoError.encodingError(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion?(false, MobiqoError.networkError(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(false, MobiqoError.invalidResponse)
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                completion?(false, MobiqoError.apiError(statusCode: httpResponse.statusCode, message: "Track event failed. Raw response: \(String(data: data ?? Data(), encoding: .utf8) ?? "")"))
                return
            }
            completion?(true, nil)
        }.resume()
    }

    /// Retrieves user information from Mobiqo.
    ///
    /// Fetches stored user data and analytics information for a specific user.
    /// Useful for displaying user stats or personalizing the app experience.
    ///
    /// - Parameters:
    ///   - revenueCatUserId: The RevenueCat user identifier to look up.
    ///   - completion: A closure called with the result of the operation.
    ///                 It receives a `Result` containing either a `GetUserInfoResponse` on success
    ///                 or an `Error` on failure.
    public func getUserInfo(revenueCatUserId: String, completion: @escaping (Result<GetUserInfoResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/getAppUser") else {
            completion(.failure(MobiqoError.invalidUrl))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["revenue_cat_user_id": revenueCatUserId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(MobiqoError.encodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(MobiqoError.networkError(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(MobiqoError.invalidResponse))
                return
            }

            guard httpResponse.statusCode == 200 else {
                completion(.failure(MobiqoError.apiError(statusCode: httpResponse.statusCode, message: "Get user info failed. Raw response: \(String(data: data, encoding: .utf8) ?? "")")))
                return
            }

            do {
                let userInfoResponse = try JSONDecoder().decode(GetUserInfoResponse.self, from: data)
                completion(.success(userInfoResponse))
            } catch {
                completion(.failure(MobiqoError.decodingError(error)))
            }
        }.resume()
    }

    /// Starts a periodic heartbeat timer that sends a signal to the Mobiqo backend.
    /// This helps in tracking user sessions and activity.
    /// The heartbeat interval is fixed at 30 seconds to match Capacitor SDK.
    /// This method is called internally upon successful user sync.
    private func startHeartbeat() {
        DispatchQueue.main.async { // Ensure timer operations are on the main thread
            self.heartbeatTimer?.invalidate() // Invalidate existing timer to prevent multiples
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
    }

    /// Sends a single heartbeat signal to the Mobiqo backend.
    /// This is called periodically by the `startHeartbeat` timer.
    /// Heartbeats are sent only if a session ID is available.
    private func sendHeartbeat() {
        guard let currentSessionId = sessionId else {
            print("MobiqoSDK: Heartbeat skipped - Session ID not found.")
            return
        }

        guard let url = URL(string: "\(apiBaseUrl)/heartbeat") else {
            print("MobiqoSDK: Invalid heartbeat URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["session_id": currentSessionId]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("MobiqoSDK: Failed to encode heartbeat body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("MobiqoSDK: Heartbeat request failed: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("MobiqoSDK: Invalid heartbeat response")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("MobiqoSDK: Heartbeat failed with status code: \(httpResponse.statusCode).")
                return
            }
            
            // Handle potential session ID update from heartbeat response
            if let data = data,
               let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let newSessionId = jsonResponse["sessionId"] as? String {
                self.sessionId = newSessionId
                self.userDefaults.set(newSessionId, forKey: UserDefaultsKeys.sessionId.rawValue)
            }
        }.resume()
    }

    /// Disposes of the Mobiqo SDK instance.
    ///
    /// This method clears all persisted SDK data from UserDefaults and stops any ongoing 
    /// processes like the heartbeat timer. Call this if you need to reset the SDK or when 
    /// a user logs out and you want to ensure their data is cleared from the device.
    public func dispose() {
        DispatchQueue.main.async { // Ensure timer invalidation is on the main thread
            self.heartbeatTimer?.invalidate()
            self.heartbeatTimer = nil
        }
        projectId = nil
        sessionId = nil
        userDefaults.removeObject(forKey: UserDefaultsKeys.projectId.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKeys.sessionId.rawValue)
        print("MobiqoSDK: Disposed.")
    }

    /// Ensures the heartbeat timer is invalidated when the Mobiqo instance is deinitialized.
    deinit {
        DispatchQueue.main.async {
            self.heartbeatTimer?.invalidate()
        }
    }
}

/// Extension to provide a convenience method for encoding `Encodable` objects to `Data`.
internal extension Encodable {
    /// Encodes the conforming object into `Data`.
    /// - Returns: `Data` representation of the object, or `nil` if encoding fails.
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

// Note: The `AppUser` struct in `Models.swift` has all properties as `let`.
// If any of these need to be updatable on the client after initial sync (e.g., `activeEntitlements`),
// they should be `var` or you'd need a mechanism to re-sync with new values.
// For now, assuming `AppUser` is largely static client-side after sync, with updates driven by server responses.
// The `firstSeenAt` and `lastSeenAt` are also marked as `let` and typically set by the server.
// The payload for `syncUser` sends them as empty or current values, and the server decides the canonical values.
// The provided `AppUser` struct is suitable for sending data to the server.
// The server's response (`SyncUserResponse.appUser`) will contain the canonical, possibly updated, `AppUser` data.
// It's important that the client uses the `AppUser` data from the `SyncUserResponse` as the source of truth after a sync.
// The `userId` is updated from `syncResponse.appUser.id`. If other fields need local updating, handle similarly.


/// Defines the set of errors that can be thrown by the Mobiqo SDK.
public enum MobiqoError: Error, LocalizedError {
    /// Indicates that the SDK was not initialized before calling a method that requires it.
    /// Call `Mobiqo.shared.initialize()` first.
    case sdkNotInitialized
    /// Indicates that the SDK was not initialized or the user has not been synced yet.
    /// Call `Mobiqo.shared.initialize()` and `Mobiqo.shared.syncUser()` first.
    case sdkNotInitializedOrUserNotSynced
    /// Indicates that an invalid URL was constructed, typically an internal SDK issue.
    case invalidUrl
    /// Wraps a network error that occurred during an API request (e.g., no internet connection).
    case networkError(Error)
    /// Indicates an invalid or unexpected response was received from the server (e.g., missing data).
    case invalidResponse
    /// Wraps an error that occurred during JSON decoding of a server response.
    case decodingError(Error)
    /// Wraps an error that occurred during JSON encoding of a request body.
    case encodingError(Error)
    /// Indicates an API error with a specific status code and message from the server.
    case apiError(statusCode: Int, message: String)
    /// Indicates a general failure during the SDK initialization process (e.g., unauthorized).
    case initializationFailed(String)

    /// Provides a human-readable description for each error case.
    public var errorDescription: String? {
        switch self {
        case .sdkNotInitialized:
            return "Mobiqo SDK has not been initialized. Please call Mobiqo.shared.initialize() first."
        case .sdkNotInitializedOrUserNotSynced:
            return "Mobiqo SDK has not been initialized or the user has not been synced. Call initialize() and syncUser() first."
        case .invalidUrl:
            return "Internal SDK error: An invalid URL was constructed."
        case .networkError(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid or unexpected response from the server."
        case .decodingError(let underlyingError):
            return "Failed to decode server response: \(underlyingError.localizedDescription)"
        case .encodingError(let underlyingError):
            return "Failed to encode request body: \(underlyingError.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API request failed with status code \(statusCode): \(message)"
        case .initializationFailed(let message):
            return "Mobiqo SDK initialization failed: \(message)"
        }
    }
}
