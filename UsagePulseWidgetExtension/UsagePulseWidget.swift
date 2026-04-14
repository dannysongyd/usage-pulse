import SwiftUI
import WidgetKit

import UsagePulseShared

struct UsagePulseEntry: TimelineEntry {
    let date: Date
    let dashboard: UsageDashboardState
}

struct UsagePulseTimelineProvider: TimelineProvider {
    private let store = UsageDashboardStore()
    private let coordinator = UsageCoordinator()

    func placeholder(in context: Context) -> UsagePulseEntry {
        UsagePulseEntry(date: .now, dashboard: coordinator.refresh(useDemoData: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (UsagePulseEntry) -> Void) {
        completion(UsagePulseEntry(date: .now, dashboard: resolvedDashboard(referenceDate: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsagePulseEntry>) -> Void) {
        let start = Date()
        let entries = (0..<4).map { offset -> UsagePulseEntry in
            let entryDate = start.addingTimeInterval(TimeInterval(offset * 30 * 60))
            return UsagePulseEntry(date: entryDate, dashboard: resolvedDashboard(referenceDate: entryDate))
        }

        completion(Timeline(entries: entries, policy: .after(start.addingTimeInterval(2 * 60 * 60))))
    }

    private func resolvedDashboard(referenceDate: Date) -> UsageDashboardState {
        let cached = store.loadDashboard()
        if cached.providers.isEmpty {
            return coordinator.refresh(useDemoData: store.loadDemoMode(), referenceDate: referenceDate)
        }

        return cached
    }
}

struct UsagePulseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UsagePulseWidget", provider: UsagePulseTimelineProvider()) { entry in
            UsagePulseWidgetView(entry: entry)
        }
        .configurationDisplayName("UsagePulse")
        .description("Claude and Codex usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct UsagePulseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UsagePulseEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumUsageWidget(dashboard: entry.dashboard)
            default:
                SmallUsageWidget(provider: entry.dashboard.smallWidgetProvider(referenceDate: entry.date))
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.12, blue: 0.17),
                    Color(red: 0.05, green: 0.07, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct SmallUsageWidget: View {
    let provider: ProviderUsageState?

    var body: some View {
        if let provider {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(provider.provider.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(provider.status.source.displayLabel)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.8))
                }

                if let snapshot = provider.rollingFiveHourSnapshot {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(UsageFormatters.percentageText(for: snapshot.clampedRatio))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(snapshot.usedLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.72))

                        Text(UsageFormatters.resetLine(resetDate: snapshot.resetDate))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                } else {
                    Text(provider.status.detailMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer()
            }
            .padding(18)
        } else {
            Text("No cached usage yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(18)
        }
    }
}

private struct MediumUsageWidget: View {
    let dashboard: UsageDashboardState

    var body: some View {
        HStack(spacing: 16) {
            ForEach(dashboard.providers) { provider in
                VStack(alignment: .leading, spacing: 10) {
                    Text(provider.provider.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    if let rolling = provider.rollingFiveHourSnapshot {
                        Text(UsageFormatters.percentageText(for: rolling.clampedRatio))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(rolling.usedLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))

                        if let weekly = provider.weeklySnapshot {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.78))
                                        .frame(maxWidth: 120 * weekly.clampedRatio)
                                }
                                .frame(height: 10)

                            Text(weekly.usedLabel)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.54))
                        }
                    } else {
                        Text(provider.status.source.displayLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.82))

                        Text(provider.status.detailMessage)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
    }
}

