import SwiftUI
import Combine

@MainActor
final class DatePickerViewModel: ObservableObject {
    @Published var baseMonth: Date
    @Published private(set) var startDate: Date?
    @Published private(set) var endDate: Date?

    /// Max span of the selected range, in calendar days, INCLUSIVE of both
    /// endpoints (7 = start and end at most 6 days apart).
    let maxRangeSpanDays: Int
    private var calendar: Calendar

    init(maxRangeSpanDays: Int = 7, referenceDate: Date = Date()) {
        self.maxRangeSpanDays = maxRangeSpanDays
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        self.calendar = cal
        self.baseMonth = referenceDate.startOfMonth(using: cal)
    }

    var nextMonth: Date {
        calendar.date(byAdding: .month, value: 1, to: baseMonth) ?? baseMonth
    }

    func goToPreviousMonth() {
        baseMonth = calendar.date(byAdding: .month, value: -1, to: baseMonth) ?? baseMonth
    }

    func goToNextMonth() {
        baseMonth = calendar.date(byAdding: .month, value: 1, to: baseMonth) ?? baseMonth
    }

    func select(_ date: Date) {
        let day = calendar.startOfDay(for: date)

        guard let start = startDate, endDate == nil else {
            startDate = day
            endDate = nil
            return
        }

        if day < start {
            startDate = day
            endDate = nil
            return
        }

        let span = (calendar.dateComponents([.day], from: start, to: day).day ?? 0) + 1
        if span > maxRangeSpanDays {
            // Restart the selection rather than clamping to day N — clamping
            // would silently pick an end date the user never tapped.
            startDate = day
            endDate = nil
        } else {
            endDate = day
        }
    }

    func reset() {
        startDate = nil
        endDate = nil
    }

    func isStart(_ date: Date) -> Bool {
        guard let start = startDate else { return false }
        return calendar.isDate(date, inSameDayAs: start)
    }

    func isEnd(_ date: Date) -> Bool {
        guard let end = endDate else { return false }
        return calendar.isDate(date, inSameDayAs: end)
    }

    func isInRange(_ date: Date) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        return date >= start && date <= end
    }

    /// Builds the 6-ish rows of a month grid, Monday-first, with leading and
    /// trailing padding cells from adjacent months so the grid is always a
    /// clean multiple of 7.
    func weeks(for monthDate: Date) -> [[DatePickerModel]] {
        let monthStart = monthDate.startOfMonth(using: calendar)
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        let firstWeekdayOfMonth = calendar.component(.weekday, from: monthStart)
        let leadingEmptyCount = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7

        var days: [DatePickerModel] = []

        if leadingEmptyCount > 0,
           let prevMonth = calendar.date(byAdding: .month, value: -1, to: monthStart),
           let prevRange = calendar.range(of: .day, in: .month, for: prevMonth) {
            let prevCount = prevRange.count
            for offset in stride(from: leadingEmptyCount, to: 0, by: -1) {
                days.append(DatePickerModel(date: nil, dayNumber: prevCount - offset + 1, isCurrentMonth: false))
            }
        }

        for dayNumber in range {
            let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart)
            days.append(DatePickerModel(date: date, dayNumber: dayNumber, isCurrentMonth: true))
        }

        let trailingCount = (7 - days.count % 7) % 7
        if trailingCount > 0 {
            for dayNumber in 1...trailingCount {
                days.append(DatePickerModel(date: nil, dayNumber: dayNumber, isCurrentMonth: false))
            }
        }

        return stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
}

private extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: comps) ?? self
    }
}
