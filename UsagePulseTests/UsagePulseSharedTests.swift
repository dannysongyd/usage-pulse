import XCTest
@testable import UsagePulseShared

final class UsagePulseSharedTests: XCTestCase {
    func testCoordinatorReturnsDemoSnapshots() {
        let state = UsageCoordinator().refresh(useDemoData: true, referenceDate: Date(timeIntervalSince1970: 1_000_000))

        XCTAssertEqual(state.providers.count, 2)
        XCTAssertEqual(state.supportedProviderCount, 2)
        XCTAssertEqual(state.provider(.claude)?.snapshots.count, 2)
        XCTAssertEqual(state.provider(.codex)?.snapshots.count, 2)
    }

    func testCoordinatorReturnsUnsupportedStatesWithoutSnapshots() {
        let state = UsageCoordinator().refresh(useDemoData: false, referenceDate: Date(timeIntervalSince1970: 1_000_000))

        XCTAssertEqual(state.providers.count, 2)
        XCTAssertEqual(state.supportedProviderCount, 0)
        XCTAssertEqual(state.provider(.claude)?.status.status, .unsupportedPersonalPlan)
        XCTAssertEqual(state.provider(.codex)?.status.status, .unsupportedPersonalPlan)
        XCTAssertTrue(state.providers.allSatisfy { $0.snapshots.isEmpty })
    }

    func testStoreRoundTripPersistsDashboardAndDemoMode() {
        let suiteName = "UsagePulseTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = UsageDashboardStore(defaults: defaults)
        let state = UsageCoordinator().refresh(useDemoData: true, referenceDate: Date(timeIntervalSince1970: 1_200_000))

        store.saveDashboard(state)
        store.saveDemoMode(false)

        XCTAssertEqual(store.loadDashboard(), state)
        XCTAssertFalse(store.loadDemoMode())

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testSmallWidgetProviderRotatesEveryThirtyMinutes() {
        let referenceDate = Date(timeIntervalSince1970: 1_500_000)
        let state = UsageCoordinator().refresh(useDemoData: true, referenceDate: referenceDate)

        let firstSlot = state.smallWidgetProvider(referenceDate: referenceDate)
        let secondSlot = state.smallWidgetProvider(referenceDate: referenceDate.addingTimeInterval(31 * 60))

        XCTAssertNotNil(firstSlot)
        XCTAssertNotNil(secondSlot)
        XCTAssertNotEqual(firstSlot?.provider, secondSlot?.provider)
    }

    func testTimeUntilResetFormatting() {
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let resetDate = referenceDate.addingTimeInterval(65 * 60)

        XCTAssertEqual(
            UsageFormatters.timeUntilResetString(resetDate: resetDate, referenceDate: referenceDate),
            "1h 5m"
        )
    }
}

