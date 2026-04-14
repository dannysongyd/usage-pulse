import Foundation

public enum ProviderID: String, Codable, CaseIterable, Hashable, Identifiable {
    case claude
    case codex

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude:
            return "Claude"
        case .codex:
            return "Codex"
        }
    }

    public var summaryLine: String {
        switch self {
        case .claude:
            return "Anthropic personal usage"
        case .codex:
            return "OpenAI coding usage"
        }
    }
}

public enum UsageWindow: String, Codable, CaseIterable, Hashable, Identifiable {
    case rollingFiveHours
    case weekly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .rollingFiveHours:
            return "Rolling 5-Hour Window"
        case .weekly:
            return "Weekly Window"
        }
    }

    public var shortLabel: String {
        switch self {
        case .rollingFiveHours:
            return "5H"
        case .weekly:
            return "WEEK"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .rollingFiveHours:
            return 0
        case .weekly:
            return 1
        }
    }
}

public enum UsageSource: String, Codable, Hashable {
    case demo
    case official
    case unsupported

    public var displayLabel: String {
        switch self {
        case .demo:
            return "Demo"
        case .official:
            return "Official"
        case .unsupported:
            return "Unsupported"
        }
    }
}

public enum ProviderStatus: String, Codable, Hashable {
    case demoAvailable
    case unsupportedPersonalPlan
    case error

    public var displayLabel: String {
        switch self {
        case .demoAvailable:
            return "Demo Ready"
        case .unsupportedPersonalPlan:
            return "Official API Unavailable"
        case .error:
            return "Error"
        }
    }
}

public struct ProviderStatusInfo: Codable, Hashable {
    public var status: ProviderStatus
    public var source: UsageSource
    public var detailMessage: String

    public init(status: ProviderStatus, source: UsageSource, detailMessage: String) {
        self.status = status
        self.source = source
        self.detailMessage = detailMessage
    }
}

public struct UsageSnapshot: Codable, Hashable, Identifiable {
    public var provider: ProviderID
    public var window: UsageWindow
    public var usedRatio: Double
    public var usedLabel: String
    public var resetDate: Date
    public var freshness: Date
    public var source: UsageSource

    public init(
        provider: ProviderID,
        window: UsageWindow,
        usedRatio: Double,
        usedLabel: String,
        resetDate: Date,
        freshness: Date,
        source: UsageSource
    ) {
        self.provider = provider
        self.window = window
        self.usedRatio = usedRatio
        self.usedLabel = usedLabel
        self.resetDate = resetDate
        self.freshness = freshness
        self.source = source
    }

    public var id: String {
        "\(provider.rawValue)-\(window.rawValue)"
    }

    public var clampedRatio: Double {
        min(max(usedRatio, 0), 1)
    }
}

public struct ProviderUsageState: Codable, Hashable, Identifiable {
    public var provider: ProviderID
    public var status: ProviderStatusInfo
    public var snapshots: [UsageSnapshot]
    public var lastUpdated: Date

    public init(
        provider: ProviderID,
        status: ProviderStatusInfo,
        snapshots: [UsageSnapshot],
        lastUpdated: Date
    ) {
        self.provider = provider
        self.status = status
        self.snapshots = snapshots
        self.lastUpdated = lastUpdated
    }

    public var id: ProviderID { provider }

    public var sortedSnapshots: [UsageSnapshot] {
        snapshots.sorted { lhs, rhs in
            lhs.window.sortOrder < rhs.window.sortOrder
        }
    }

    public var rollingFiveHourSnapshot: UsageSnapshot? {
        snapshots.first { $0.window == .rollingFiveHours }
    }

    public var weeklySnapshot: UsageSnapshot? {
        snapshots.first { $0.window == .weekly }
    }
}

public struct UsageDashboardState: Codable, Hashable {
    public var providers: [ProviderUsageState]
    public var generatedAt: Date

    public init(providers: [ProviderUsageState], generatedAt: Date) {
        self.providers = providers
        self.generatedAt = generatedAt
    }

    public static func empty(referenceDate: Date = .now) -> UsageDashboardState {
        UsageDashboardState(providers: [], generatedAt: referenceDate)
    }

    public var supportedProviderCount: Int {
        providers.filter { !$0.snapshots.isEmpty }.count
    }

    public func provider(_ providerID: ProviderID) -> ProviderUsageState? {
        providers.first { $0.provider == providerID }
    }

    public func smallWidgetProvider(referenceDate: Date = .now) -> ProviderUsageState? {
        let sortedProviders = providers.sorted { lhs, rhs in
            if lhs.lastUpdated != rhs.lastUpdated {
                return lhs.lastUpdated > rhs.lastUpdated
            }

            return lhs.provider.rawValue < rhs.provider.rawValue
        }

        guard !sortedProviders.isEmpty else {
            return nil
        }

        let slot = Calendar.current.component(.minute, from: referenceDate) / 30
        return sortedProviders[slot % sortedProviders.count]
    }
}

