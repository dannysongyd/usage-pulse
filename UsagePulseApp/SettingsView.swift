import SwiftUI

import UsagePulseShared

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section("Data Source") {
                Toggle("Use demo data for unsupported personal-account surfaces", isOn: Binding(
                    get: { model.demoMode },
                    set: { model.updateDemoMode($0) }
                ))

                Text("When enabled, the app and widget render polished sample data so layout, caching, and glanceability remain useful even without official personal-account usage APIs.")
                    .foregroundStyle(.secondary)

                Button("Refresh cache now") {
                    model.refresh()
                }
            }

            Section("Widget Preview") {
                WidgetPreviewCard(dashboard: model.dashboard)
                    .frame(height: 170)
            }

            Section("Shared Storage") {
                LabeledContent("App Group", value: UsageDashboardStore.appGroupID)
                LabeledContent("Bundle Prefix", value: "com.dannysongyd.usagepulse")
            }
        }
        .formStyle(.grouped)
        .padding(18)
    }
}

private struct WidgetPreviewCard: View {
    let dashboard: UsageDashboardState

    var body: some View {
        let provider = dashboard.smallWidgetProvider() ?? dashboard.providers.first

        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.14, blue: 0.19),
                            Color(red: 0.07, green: 0.09, blue: 0.13)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let provider {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Widget")
                            .font(.system(size: 11, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.white.opacity(0.52))

                        Text(provider.provider.displayName)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(provider.status.source.displayLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }

                    Spacer()

                    if let snapshot = provider.rollingFiveHourSnapshot {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(UsageFormatters.percentageText(for: snapshot.clampedRatio))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(snapshot.usedLabel)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.68))
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

