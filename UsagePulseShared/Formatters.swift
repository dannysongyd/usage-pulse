import Foundation

public enum UsageFormatters {
    private static let absoluteTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public static func percentageText(for ratio: Double) -> String {
        "\(Int((min(max(ratio, 0), 1) * 100).rounded()))%"
    }

    public static func timeUntilResetString(resetDate: Date, referenceDate: Date = .now) -> String {
        let totalSeconds = max(Int(resetDate.timeIntervalSince(referenceDate)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        if minutes > 0 {
            return "\(minutes)m"
        }

        return "under 1m"
    }

    public static func resetLine(resetDate: Date, referenceDate: Date = .now) -> String {
        "Resets in \(timeUntilResetString(resetDate: resetDate, referenceDate: referenceDate))"
    }

    public static func freshnessLine(freshness: Date, referenceDate: Date = .now) -> String {
        let totalSeconds = max(Int(referenceDate.timeIntervalSince(freshness)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "Updated \(hours)h ago"
        }

        if minutes > 0 {
            return "Updated \(minutes)m ago"
        }

        return "Updated just now"
    }

    public static func absoluteResetLine(resetDate: Date) -> String {
        absoluteTimeFormatter.string(from: resetDate)
    }
}

