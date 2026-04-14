import SwiftUI

import UsagePulseShared

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    private let columns = [
        GridItem(.flexible(minimum: 320), spacing: 20),
        GridItem(.flexible(minimum: 320), spacing: 20)
    ]

    var body: some View {
        ZStack {
            DashboardBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    providerGrid
                    footer
                }
                .padding(32)
            }
        }
        .frame(minWidth: 1120, minHeight: 780)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    model.refresh()
                } label: {
                    Label(model.isRefreshing ? "Refreshing…" : "Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command])

                SettingsLink {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("UsagePulse")
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Claude and Codex usage in one calm, glanceable macOS surface.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .frame(maxWidth: 560, alignment: .leading)

                HStack(spacing: 10) {
                    HeroChip(title: model.demoMode ? "Demo mode" : "Official-only mode", systemImage: model.demoMode ? "sparkles" : "lock.shield")
                    HeroChip(title: "\(model.dashboard.supportedProviderCount) providers with chart data", systemImage: "chart.xyaxis.line")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                Text("Shared app + widget cache")
                    .font(.system(size: 12, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.white.opacity(0.58))

                Text(UsageFormatters.absoluteResetLine(resetDate: model.dashboard.generatedAt))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Personal-account bars are surfaced honestly: demo when useful, unsupported when official APIs stop.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(maxWidth: 320, alignment: .trailing)
            }
            .padding(20)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.14, blue: 0.22),
                            Color(red: 0.08, green: 0.10, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var providerGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(model.dashboard.providers) { state in
                ProviderCardView(state: state)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current product boundary")
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.white.opacity(0.55))

            Text("Claude personal plans and Codex personal/local usage are not officially queryable from stable public APIs today, so the UI is built to degrade cleanly instead of pretending otherwise.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.74))
                .frame(maxWidth: 840, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }
}

private struct HeroChip: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white.opacity(0.08), in: Capsule())
    }
}

private struct DashboardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.07),
                    Color(red: 0.06, green: 0.08, blue: 0.11),
                    Color(red: 0.08, green: 0.11, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.29, green: 0.78, blue: 0.75).opacity(0.25))
                .frame(width: 440, height: 440)
                .blur(radius: 120)
                .offset(x: -320, y: -220)

            Circle()
                .fill(Color(red: 0.19, green: 0.45, blue: 0.82).opacity(0.18))
                .frame(width: 540, height: 540)
                .blur(radius: 160)
                .offset(x: 360, y: 260)
        }
        .ignoresSafeArea()
    }
}

