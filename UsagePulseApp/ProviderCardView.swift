import SwiftUI

import UsagePulseShared

struct ProviderCardView: View {
    let state: ProviderUsageState

    private var tint: Color {
        switch state.provider {
        case .claude:
            return Color(red: 0.95, green: 0.53, blue: 0.36)
        case .codex:
            return Color(red: 0.32, green: 0.82, blue: 0.76)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            if let rolling = state.rollingFiveHourSnapshot, let weekly = state.weeklySnapshot {
                HStack(alignment: .center, spacing: 24) {
                    UsageRingView(snapshot: rolling, tint: tint)

                    VStack(alignment: .leading, spacing: 18) {
                        UsageBarView(snapshot: weekly, tint: tint)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(state.status.detailMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.72))

                            Text(UsageFormatters.freshnessLine(freshness: rolling.freshness))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.48))
                        }
                    }
                }
            } else {
                UnsupportedStateView(status: state.status, tint: tint)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.42), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(tint)
                        .frame(width: 10, height: 10)

                    Text(state.provider.displayName)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(state.provider.summaryLine)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
            }

            Spacer()

            Text(state.status.source.displayLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(tint.opacity(0.18), in: Capsule())
        }
    }
}

struct UsageRingView: View {
    let snapshot: UsageSnapshot
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 18)

            Circle()
                .trim(from: 0, to: snapshot.clampedRatio)
                .stroke(
                    AngularGradient(
                        colors: [Color.white.opacity(0.85), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text(snapshot.window.shortLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.52))

                Text(UsageFormatters.percentageText(for: snapshot.clampedRatio))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(snapshot.usedLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 176, height: 176)
    }
}

struct UsageBarView: View {
    let snapshot: UsageSnapshot
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.window.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(UsageFormatters.percentageText(for: snapshot.clampedRatio))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.58), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.width * snapshot.clampedRatio, 18))
                }
            }
            .frame(height: 16)

            Text(snapshot.usedLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.72))

            HStack {
                Label(UsageFormatters.resetLine(resetDate: snapshot.resetDate), systemImage: "timer")
                Spacer()
                Text(UsageFormatters.absoluteResetLine(resetDate: snapshot.resetDate))
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.46))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct UnsupportedStateView: View {
    let status: ProviderStatusInfo
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(status.status.displayLabel, systemImage: "lock.slash")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(status.detailMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.76))
                .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.28), lineWidth: 1)
                )
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(tint)

                        Text("The widget still works, but it can only render demo or cached data until an official personal-account source exists.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                )
        }
    }
}

