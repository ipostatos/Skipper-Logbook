import Foundation

extension Date {
    /// "SUNDAY, 13 JAN 2026" style header used above each day's log entries.
    func logDayHeader(locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("EEEE d MMM yyyy")
        return f.string(from: self).uppercased(with: locale)
    }

    /// Short "12 Jun 2025" for cards / rows.
    func shortDate(locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }

    /// "09:32" wall-clock time for log rows.
    func hourMinute(locale: Locale = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("HH:mm")
        return f.string(from: self)
    }

    /// Groups a collection into day buckets keyed by start-of-day, newest first.
    static func groupByDay<T>(_ items: [T], date: (T) -> Date, calendar: Calendar = .current) -> [(day: Date, items: [T])] {
        let groups = Dictionary(grouping: items) { calendar.startOfDay(for: date($0)) }
        return groups
            .map { (day: $0.key, items: $0.value) }
            .sorted { $0.day > $1.day }
    }
}

extension TimeInterval {
    /// Compact "10d 2h 14m" duration used for time-underway / ETA.
    var durationDHM: String {
        let total = Int(max(0, self))
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        let seconds = total % 60
        return "\(minutes)m \(seconds)s"
    }

    /// "00:48" mm:ss stopwatch for the active MOB / anchor-watch timers.
    var stopwatchMMSS: String {
        let total = Int(max(0, self))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// "1:02:04" h:mm:ss when a watch runs past an hour.
    var stopwatchHMS: String {
        let total = Int(max(0, self))
        let h = total / 3_600, m = (total % 3_600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }
}
