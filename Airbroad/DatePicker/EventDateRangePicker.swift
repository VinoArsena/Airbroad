import SwiftUI
import Combine

// MARK: - Model

struct EventCalendarDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int
}

// MARK: - View model

@MainActor
final class EventDateRangeViewModel: ObservableObject {
    enum ActiveField { case start, end }

    @Published var isAllDay = false
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var activeField: ActiveField?
    @Published var visibleMonth: Date

    /// Max span between start and end, in calendar days, inclusive of both
    /// endpoints — carried over from the original "max 7 days" requirement.
    let maxRangeSpanDays: Int
    private var calendar: Calendar

    init(maxRangeSpanDays: Int = 7, referenceDate: Date = Date()) {
        self.maxRangeSpanDays = maxRangeSpanDays
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1 // Sunday, matching the native Calendar app
        self.calendar = cal

        let roundedStart = cal.date(bySettingHour: 10, minute: 0, second: 0, of: referenceDate) ?? referenceDate
        self.startDate = roundedStart
        self.endDate = cal.date(byAdding: .hour, value: 1, to: roundedStart) ?? roundedStart
        self.visibleMonth = roundedStart.startOfMonth(using: cal)
        self.activeField = nil
    }

    // MARK: Row taps — tapping an already-open field's chip collapses it,
    // matching how the native app lets you dismiss by tapping again.

    func tapStartsRow() {
        activeField = (activeField == .start) ? nil : .start
        visibleMonth = startDate.startOfMonth(using: calendar)
    }

    func tapEndsRow() {
        activeField = (activeField == .end) ? nil : .end
        visibleMonth = endDate.startOfMonth(using: calendar)
    }

    // MARK: Calendar day selection

    func selectDay(_ day: Date) {
        switch activeField {
        case .start:
            // Keep the existing time-of-day, only replace the date — you
            // shouldn't lose your chosen start time by changing the day.
            startDate = combine(day: day, withTimeFrom: startDate)
            if endDate < startDate {
                // Matches native Calendar: pushing start past end drags end along.
                endDate = startDate
            }
            // Auto-advance to Ends — the whole point of this interaction.
            activeField = .end
            visibleMonth = endDate.startOfMonth(using: calendar)

        case .end:
            let candidate = combine(day: day, withTimeFrom: endDate)
            let span = (calendar.dateComponents([.day], from: startDate, to: candidate).day ?? 0) + 1
            if candidate < startDate {
                endDate = candidate
            } else if span > maxRangeSpanDays {
                endDate = calendar.date(byAdding: .day, value: maxRangeSpanDays - 1, to: startDate) ?? candidate
            } else {
                endDate = candidate
            }
            activeField = nil // nothing after Ends — collapse

        case .none:
            break
        }
    }

    func goToPreviousMonth() {
        visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
    }

    func goToNextMonth() {
        visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
    }

    func isSelected(_ date: Date) -> Bool {
        switch activeField {
        case .start: return calendar.isDate(date, inSameDayAs: startDate)
        case .end: return calendar.isDate(date, inSameDayAs: endDate)
        case .none: return false
        }
    }

    /// Sunday-first grid. Leading/trailing padding cells are blank (no
    /// adjacent-month day numbers), matching the native Calendar app's look
    /// — unlike a typical dual-month range picker that greys in neighbor days.
    func weeks(for monthDate: Date) -> [[EventCalendarDay]] {
        let monthStart = monthDate.startOfMonth(using: calendar)
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        let firstWeekdayOfMonth = calendar.component(.weekday, from: monthStart)
        let leadingEmptyCount = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7

        var days: [EventCalendarDay] = []
        for _ in 0..<leadingEmptyCount {
            days.append(EventCalendarDay(date: nil, dayNumber: 0))
        }
        for dayNumber in range {
            let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart)
            days.append(EventCalendarDay(date: date, dayNumber: dayNumber))
        }
        let trailingCount = (7 - days.count % 7) % 7
        for _ in 0..<trailingCount {
            days.append(EventCalendarDay(date: nil, dayNumber: 0))
        }

        return stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }

    private func combine(day: Date, withTimeFrom timeSource: Date) -> Date {
        let dayComps = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComps = calendar.dateComponents([.hour, .minute, .second], from: timeSource)
        var merged = DateComponents()
        merged.year = dayComps.year
        merged.month = dayComps.month
        merged.day = dayComps.day
        merged.hour = timeComps.hour
        merged.minute = timeComps.minute
        merged.second = timeComps.second
        return calendar.date(from: merged) ?? day
    }
}

private extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: comps) ?? self
    }
}

// MARK: - Views

struct EventDateRangePicker: View {
    @StateObject private var viewModel: EventDateRangeViewModel
    let onChange: (Date, Date) -> Void

    init(
        maxRangeSpanDays: Int = 7,
        onChange: @escaping (Date, Date) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: EventDateRangeViewModel(maxRangeSpanDays: maxRangeSpanDays))
        self.onChange = onChange
    }

    var body: some View {
        VStack(spacing: 0) {
            allDayRow
            Divider().padding(.leading)

            dateRow(title: "Starts", dateBinding: $viewModel.startDate, field: .start)
            Divider().padding(.leading)

            if viewModel.activeField == .start {
                InlineMonthCalendarView(viewModel: viewModel)
                Divider().padding(.leading)
            }

            dateRow(title: "Ends", dateBinding: $viewModel.endDate, field: .end)

            if viewModel.activeField == .end {
                Divider().padding(.leading)
                InlineMonthCalendarView(viewModel: viewModel)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onChange(of: viewModel.startDate) { _, _ in notify() }
        .onChange(of: viewModel.endDate) { _, _ in notify() }
    }

    private var allDayRow: some View {
        HStack {
            Text("All-day")
            Spacer()
            Toggle("", isOn: $viewModel.isAllDay)
                .labelsHidden()
        }
        .padding()
    }

    private func dateRow(
        title: String,
        dateBinding: Binding<Date>,
        field: EventDateRangeViewModel.ActiveField
    ) -> some View {
        HStack {
            Text(title)
            Spacer()

            Button {
                field == .start ? viewModel.tapStartsRow() : viewModel.tapEndsRow()
            } label: {
                // Format order/localization here follows the device locale
                // automatically — same as the native app, so "10 Aug 2026"
                // vs "Aug 10, 2026" depends on the user's region, not a bug.
                Text(dateBinding.wrappedValue, format: .dateTime.day().month(.abbreviated).year())
                    .foregroundStyle(viewModel.activeField == field ? Color.accentColor : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if !viewModel.isAllDay {
                DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
        }
        .padding()
    }

    private func notify() {
        onChange(viewModel.startDate, viewModel.endDate)
    }
}

private struct InlineMonthCalendarView: View {
    @ObservedObject var viewModel: EventDateRangeViewModel
    private let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        VStack(spacing: 16) {
            header
            weekdayRow
            ForEach(Array(viewModel.weeks(for: viewModel.visibleMonth).enumerated()), id: \.offset) { _, week in
                weekRow(week)
            }
        }
        .padding()
    }

    private var header: some View {
        HStack {
            // The small chevron next to the month name is decorative here —
            // in the native app it opens a quick month/year jump picker.
            // Left out of scope; add a Menu or a UIKit month-year wheel if
            // you want that specific interaction later.
            HStack(spacing: 4) {
                Text(viewModel.visibleMonth, format: .dateTime.month(.wide).year())
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            Spacer()
            Button { viewModel.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left")
            }
            Button { viewModel.goToNextMonth() } label: {
                Image(systemName: "chevron.right")
            }
        }
        // Using the app's accent color rather than hardcoding Apple's
        // Calendar red — your AQI category colors already own red/orange/
        // green semantically, so reusing red here would clash.
        .tint(.accentColor)
    }

    private var weekdayRow: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekRow(_ week: [EventCalendarDay]) -> some View {
        HStack {
            ForEach(week) { day in
                dayCell(day)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: EventCalendarDay) -> some View {
        if let date = day.date {
            Button {
                viewModel.selectDay(date)
            } label: {
                Text("\(day.dayNumber)")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Circle().fill(viewModel.isSelected(date) ? Color.accentColor : .clear)
                    )
                    .foregroundStyle(viewModel.isSelected(date) ? .white : .primary)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

#Preview {
    ScrollView {
        EventDateRangePicker { start, end in
            print("start:", start, "end:", end)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
