import Foundation
import Observation

@Observable
class CalendarViewModel {
    let calendar: Calendar
    let forecastDaysAhead: Int
    
    // MARK: - Date State
    var selectedDate: Date
    
    // MARK: - Time Picker State
    var sliderHour12: Double
    var isPM: Bool
    
    init(
        calendar: Calendar = .singapore,
        forecastDaysAhead: Int = 3
    ) {
        self.calendar = calendar
        self.forecastDaysAhead = forecastDaysAhead
        
        // Initialize with today's start of day
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        self.selectedDate = calendar.date(from: components) ?? calendar.startOfDay(for: Date())
        
        // Initialize hour & AM/PM
        let h24 = calendar.component(.hour, from: Date())
        self.sliderHour12 = Double(h24 % 12)
        self.isPM = h24 >= 12
    }
    
    // MARK: - Computed Date Properties
    var today: Date {
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return calendar.date(from: components) ?? calendar.startOfDay(for: Date())
    }
    
    var maxSelectableDate: Date {
        calendar.date(byAdding: .day, value: forecastDaysAhead, to: today) ?? Date()
    }
    
    var next3Days: [Date] {
        (0...forecastDaysAhead).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    
    // MARK: - Computed Time Properties
    var actualHour24: Int {
        let displayedHour12 = Int(sliderHour12) == 0 ? 12 : Int(sliderHour12)
        if isPM {
            return displayedHour12 == 12 ? 12 : displayedHour12 + 12
        } else {
            return displayedHour12 == 12 ? 0 : displayedHour12
        }
    }
    
    var currentTime12Hour: String {
        let displayedHour12 = Int(sliderHour12) == 0 ? 12 : Int(sliderHour12)
        return String(format: "%d:00 %@", displayedHour12, isPM ? "PM" : "AM")
    }
    
    // MARK: - Date Selection
    func isSelectable(_ date: Date) -> Bool {
        next3Days.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    func select(date: Date) {
        guard isSelectable(date) else { return }
        selectedDate = calendar.startOfDay(for: date)
    }
}

extension Calendar {
    static let singapore: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Singapore") ?? .current
        return calendar
    }()
}

extension DateFormatter {
    static let sgWeekday: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .singapore
        f.timeZone = TimeZone(identifier: "Asia/Singapore")
        f.dateFormat = "E"
        return f
    }()
    
    static let sgDay: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .singapore
        f.timeZone = TimeZone(identifier: "Asia/Singapore")
        f.dateFormat = "d"
        return f
    }()
    
    static let sgFullTitle: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .singapore
        f.timeZone = TimeZone(identifier: "Asia/Singapore")
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()
}

extension TimeZone {
    static let singapore = TimeZone(identifier: "Asia/Singapore")!
}
