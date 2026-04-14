import Foundation

public final class UsageDashboardStore {
    public static let appGroupID = "group.com.dannysongyd.usagepulse.shared"
    public static let dashboardKey = "usagepulse.dashboard"
    public static let demoModeKey = "usagepulse.demoMode"

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(defaults: UserDefaults? = nil, suiteName: String = UsageDashboardStore.appGroupID) {
        self.defaults = defaults ?? UserDefaults(suiteName: suiteName) ?? .standard

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func loadDashboard() -> UsageDashboardState {
        guard
            let data = defaults.data(forKey: Self.dashboardKey),
            let state = try? decoder.decode(UsageDashboardState.self, from: data)
        else {
            return .empty()
        }

        return state
    }

    public func saveDashboard(_ state: UsageDashboardState) {
        guard let data = try? encoder.encode(state) else {
            return
        }

        defaults.set(data, forKey: Self.dashboardKey)
    }

    public func loadDemoMode() -> Bool {
        if defaults.object(forKey: Self.demoModeKey) == nil {
            return true
        }

        return defaults.bool(forKey: Self.demoModeKey)
    }

    public func saveDemoMode(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Self.demoModeKey)
    }
}

