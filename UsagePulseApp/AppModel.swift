import Foundation
import WidgetKit

import UsagePulseShared

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var dashboard: UsageDashboardState
    @Published private(set) var isRefreshing = false
    @Published var demoMode: Bool

    private let store: UsageDashboardStore
    private let coordinator: UsageCoordinator

    init(store: UsageDashboardStore = UsageDashboardStore(), coordinator: UsageCoordinator = UsageCoordinator()) {
        self.store = store
        self.coordinator = coordinator
        let initialDemoMode = store.loadDemoMode()
        self.demoMode = initialDemoMode

        let storedDashboard = store.loadDashboard()
        if storedDashboard.providers.isEmpty {
            let fallback = coordinator.refresh(useDemoData: initialDemoMode)
            self.dashboard = fallback
            store.saveDashboard(fallback)
        } else {
            self.dashboard = storedDashboard
        }
    }

    func refresh() {
        isRefreshing = true
        let refreshed = coordinator.refresh(useDemoData: demoMode)
        dashboard = refreshed
        store.saveDashboard(refreshed)
        store.saveDemoMode(demoMode)
        WidgetCenter.shared.reloadAllTimelines()
        isRefreshing = false
    }

    func updateDemoMode(_ isEnabled: Bool) {
        demoMode = isEnabled
        refresh()
    }
}
