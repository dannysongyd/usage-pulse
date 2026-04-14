import Foundation

public protocol UsageProvider {
    var providerID: ProviderID { get }
    func status() -> ProviderStatusInfo
    func fetchSnapshots(referenceDate: Date) throws -> [UsageSnapshot]
}

public struct UsageCoordinator {
    public init() {}

    public func refresh(useDemoData: Bool, referenceDate: Date = .now) -> UsageDashboardState {
        let providers: [any UsageProvider] = useDemoData
            ? ProviderID.allCases.map { DemoUsageProvider(providerID: $0) }
            : [ClaudeUsageProvider(), CodexUsageProvider()]

        let states = providers.map { provider in
            let status = provider.status()
            let snapshots = (try? provider.fetchSnapshots(referenceDate: referenceDate)) ?? []
            return ProviderUsageState(
                provider: provider.providerID,
                status: status,
                snapshots: snapshots,
                lastUpdated: referenceDate
            )
        }

        return UsageDashboardState(providers: states, generatedAt: referenceDate)
    }
}

public struct DemoUsageProvider: UsageProvider {
    public let providerID: ProviderID

    public init(providerID: ProviderID) {
        self.providerID = providerID
    }

    public func status() -> ProviderStatusInfo {
        ProviderStatusInfo(
            status: .demoAvailable,
            source: .demo,
            detailMessage: "Demo data keeps the desktop widget and dashboard testable until both personal-account surfaces expose official usage APIs."
        )
    }

    public func fetchSnapshots(referenceDate: Date) throws -> [UsageSnapshot] {
        switch providerID {
        case .claude:
            return [
                UsageSnapshot(
                    provider: .claude,
                    window: .rollingFiveHours,
                    usedRatio: 0.62,
                    usedLabel: "3.1h of 5h",
                    resetDate: referenceDate.addingTimeInterval(90 * 60),
                    freshness: referenceDate,
                    source: .demo
                ),
                UsageSnapshot(
                    provider: .claude,
                    window: .weekly,
                    usedRatio: 0.43,
                    usedLabel: "43% of weekly budget",
                    resetDate: nextWeeklyReset(after: referenceDate),
                    freshness: referenceDate,
                    source: .demo
                )
            ]
        case .codex:
            return [
                UsageSnapshot(
                    provider: .codex,
                    window: .rollingFiveHours,
                    usedRatio: 0.34,
                    usedLabel: "1.7h of 5h",
                    resetDate: referenceDate.addingTimeInterval(185 * 60),
                    freshness: referenceDate,
                    source: .demo
                ),
                UsageSnapshot(
                    provider: .codex,
                    window: .weekly,
                    usedRatio: 0.58,
                    usedLabel: "58% of weekly budget",
                    resetDate: nextWeeklyReset(after: referenceDate.addingTimeInterval(6 * 60 * 60)),
                    freshness: referenceDate,
                    source: .demo
                )
            ]
        }
    }

    private func nextWeeklyReset(after date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = DateComponents(hour: 9, minute: 0, weekday: 2)
        return calendar.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? date.addingTimeInterval(7 * 24 * 60 * 60)
    }
}

public struct ClaudeUsageProvider: UsageProvider {
    public let providerID: ProviderID = .claude

    public init() {}

    public func status() -> ProviderStatusInfo {
        ProviderStatusInfo(
            status: .unsupportedPersonalPlan,
            source: .unsupported,
            detailMessage: "Anthropic’s Usage & Cost Admin API is unavailable for individual accounts, so personal Claude plan bars are not officially fetchable."
        )
    }

    public func fetchSnapshots(referenceDate: Date) throws -> [UsageSnapshot] {
        []
    }
}

public struct CodexUsageProvider: UsageProvider {
    public let providerID: ProviderID = .codex

    public init() {}

    public func status() -> ProviderStatusInfo {
        ProviderStatusInfo(
            status: .unsupportedPersonalPlan,
            source: .unsupported,
            detailMessage: "OpenAI exposes Codex usage through enterprise compliance surfaces for web/cloud usage, not the personal-account local usage bars you asked to mirror."
        )
    }

    public func fetchSnapshots(referenceDate: Date) throws -> [UsageSnapshot] {
        []
    }
}
