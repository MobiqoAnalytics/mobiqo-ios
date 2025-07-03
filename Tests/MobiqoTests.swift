// mobiqo-ios/Tests/MobiqoTests.swift

import XCTest
@testable import Mobiqo // Assuming your module name is Mobiqo

// Basic MockURLProtocol for future use.
// Note: Mobiqo.swift would need to be refactored to allow injection of URLSessionConfiguration (for protocolClasses)
// or a URLSession instance directly for this to be used effectively for network mocking.
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true // Handle all requests
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("MockURLProtocol.requestHandler is not set.")
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Required override
    }
}


class MobiqoTests: XCTestCase {

    let userDefaultsSuiteName = "MobiqoTestDefaults"
    var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Use a specific UserDefaults suite for tests to avoid polluting the main app's defaults
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        userDefaults?.removePersistentDomain(forName: userDefaultsSuiteName) // Clean up before each test

        // For testing Mobiqo.shared, we need to ensure it uses our test UserDefaults.
        // This is tricky because Mobiqo.shared is a singleton initialized at first access.
        // One way is to reset the singleton, but that requires access to its internal state or a reset method.
        // For now, we will call dispose() and then re-initialize if needed by tests.
        // A proper DI approach for UserDefaults would be better.
        Mobiqo.shared.dispose() // Clear any existing state
    }

    override func tearDownWithError() throws {
        // Clean up UserDefaults after each test
        userDefaults?.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        Mobiqo.shared.dispose() // Ensure SDK state is reset
        MockURLProtocol.requestHandler = nil
        try super.tearDownWithError()
    }

    func testSingletonInstance() {
        let instance1 = Mobiqo.shared
        let instance2 = Mobiqo.shared
        XCTAssertTrue(instance1 === instance2, "Mobiqo.shared should return the same instance.")
    }

    func testEventTypeRawValues() {
        XCTAssertEqual(EventType.click.rawValue, "click")
        XCTAssertEqual(EventType.action.rawValue, "action")
        XCTAssertEqual(EventType.screenView.rawValue, "screen_view")
        XCTAssertEqual(EventType.paywallView.rawValue, "paywall_view")
        XCTAssertEqual(EventType.paywallDismiss.rawValue, "paywall_dismiss")
        XCTAssertEqual(EventType.purchaseAttempt.rawValue, "purchase_attempt")
        XCTAssertEqual(EventType.purchaseSuccess.rawValue, "purchase_success")
        XCTAssertEqual(EventType.purchaseFailed.rawValue, "purchase_failed")
        XCTAssertEqual(EventType.formSubmit.rawValue, "form_submit")
        XCTAssertEqual(EventType.navigation.rawValue, "navigation")
        XCTAssertEqual(EventType.error.rawValue, "error")
        XCTAssertEqual(EventType.custom.rawValue, "custom")
    }

    func testAppUserDecoding() throws {
        let json = """
        {
            "id": "user_123",
            "project_id": "project_abc",
            "revenue_cat_user_id": "rc_user_xyz",
            "mobiqo_username": "ios_generated_user",
            "os": "iOS",
            "os_version": "15.1",
            "app_version": "1.0.0",
            "country": "US",
            "language": "en",
            "first_seen_at": "2023-01-01T12:00:00Z",
            "last_seen_at": "2023-01-10T10:00:00Z",
            "active_entitlements": ["premium", "pro_features"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let appUser = try decoder.decode(AppUser.self, from: json)

        XCTAssertEqual(appUser.id, "user_123")
        XCTAssertEqual(appUser.projectId, "project_abc")
        XCTAssertEqual(appUser.revenueCatUserId, "rc_user_xyz")
        XCTAssertEqual(appUser.mobiqoUsername, "ios_generated_user")
        XCTAssertEqual(appUser.os, "iOS")
        XCTAssertEqual(appUser.osVersion, "15.1")
        XCTAssertEqual(appUser.appVersion, "1.0.0")
        XCTAssertEqual(appUser.country, "US")
        XCTAssertEqual(appUser.language, "en")
        XCTAssertEqual(appUser.firstSeenAt, "2023-01-01T12:00:00Z")
        XCTAssertEqual(appUser.lastSeenAt, "2023-01-10T10:00:00Z")
        XCTAssertEqual(appUser.activeEntitlements, ["premium", "pro_features"])
    }

    func testSyncUserResponseDecoding() throws {
        let json = """
        {
            "is_new_user": true,
            "app_user": {
                "id": "user_789",
                "project_id": "project_def",
                "revenue_cat_user_id": null,
                "mobiqo_username": "ios_another_user",
                "os": "iOS",
                "os_version": "14.5",
                "app_version": "1.1.0",
                "country": "CA",
                "language": "fr",
                "first_seen_at": "2023-02-01T08:00:00Z",
                "last_seen_at": "2023-02-05T18:30:00Z",
                "active_entitlements": []
            },
            "statistics": {
                "purchasing_power_parity": 0.75,
                "purchase_probability": 0.25,
                "avg_arpu": 5.50,
                "avg_arppu": 20.0,
                "avg_ltv": 50.0
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let syncResponse = try decoder.decode(SyncUserResponse.self, from: json)

        XCTAssertTrue(syncResponse.isNewUser)
        XCTAssertEqual(syncResponse.appUser.id, "user_789")
        XCTAssertEqual(syncResponse.appUser.projectId, "project_def")
        XCTAssertNil(syncResponse.appUser.revenueCatUserId)
        XCTAssertEqual(syncResponse.statistics.purchasingPowerParity, 0.75)
        XCTAssertEqual(syncResponse.statistics.purchaseProbability, 0.25)
    }

    // --- Placeholder for future tests ---

    func testInitialization_Success() {
        // TODO: Implement test for successful initialization.
        // This will require mocking network requests using MockURLProtocol.
        // Mobiqo.swift needs to be refactored to allow URLSessionConfiguration injection for testing.
        XCTMarkTestIncomplete("Initialization success test not yet implemented. Requires network mocking.")
    }

    func testInitialization_Failure_InvalidAPIKey() {
        // TODO: Implement test for failed initialization due to invalid API key.
        XCTMarkTestIncomplete("Initialization failure test not yet implemented. Requires network mocking.")
    }

    func testSyncUser_Success() {
        // TODO: Implement test for successful user sync.
        XCTMarkTestIncomplete("SyncUser success test not yet implemented. Requires network mocking and setup of initial SDK state.")
    }

    func testGetUserInfo_Success() {
        // TODO: Implement test for successful get user info.
        XCTMarkTestIncomplete("GetUserInfo test not yet implemented. Requires network mocking and setup of initial SDK state.")
    }

    func testTrackEvent_Success() {
        // TODO: Implement test for successful event tracking.
        XCTMarkTestIncomplete("TrackEvent success test not yet implemented. Requires network mocking and setup of initial SDK state.")
    }

    func testHeartbeat() {
        // TODO: Test heartbeat mechanism if possible (e.g., by checking if a request is made).
        // This might be complex to test reliably without more control over the Timer or network calls.
        XCTMarkTestIncomplete("Heartbeat test not yet implemented.")
    }

    func testDispose() {
        // Initialize, then dispose, then check if UserDefault values are cleared.
        // This is partly covered by tearDownWithError, but a specific test can be added.
        let apiKey = "testAPIKeyDispose"
        let projectId = "testProjectIDDispose"

        // To properly test dispose's effect on UserDefaults, Mobiqo needs to accept a UserDefaults instance.
        // For now, we assume it uses UserDefaults.standard, which is hard to isolate for this specific test
        // without affecting other tests or the actual app's defaults if not managed carefully.
        // The current Mobiqo.swift uses a private constant `userDefaults = UserDefaults.standard`.
        // This makes direct injection for testing difficult without code changes.

        // Simulate initialization by setting values directly in standard UserDefaults for this test.
        // Note: This is not ideal as it uses UserDefaults.standard.
        let standardDefaults = UserDefaults.standard
        standardDefaults.set(apiKey, forKey: "mobiqo_api_key")
        standardDefaults.set(projectId, forKey: "mobiqo_project_id")
        standardDefaults.set("test_user_id_dispose", forKey: "mobiqo_user_id")
        standardDefaults.set("test_mobiqo_username_dispose", forKey: "mobiqo_username")

        Mobiqo.shared.dispose()

        XCTAssertNil(standardDefaults.string(forKey: "mobiqo_api_key"), "API key should be cleared after dispose.")
        XCTAssertNil(standardDefaults.string(forKey: "mobiqo_project_id"), "Project ID should be cleared after dispose.")
        XCTAssertNil(standardDefaults.string(forKey: "mobiqo_user_id"), "User ID should be cleared after dispose.")
        XCTAssertNil(standardDefaults.string(forKey: "mobiqo_username"), "Mobiqo username should be cleared after dispose.")

        // Clean up standard UserDefaults from this test to avoid interference.
        standardDefaults.removeObject(forKey: "mobiqo_api_key")
        standardDefaults.removeObject(forKey: "mobiqo_project_id")
        standardDefaults.removeObject(forKey: "mobiqo_user_id")
        standardDefaults.removeObject(forKey: "mobiqo_username")
    }
}
```
