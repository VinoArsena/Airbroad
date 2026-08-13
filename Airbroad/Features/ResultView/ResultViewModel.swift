
import Observation
import Foundation

@Observable
class ResultViewModel {
    var selectedDate: Date = Date()
    var selectedPollutant: String = "AQI"
    
    let pollutants: [String] = [
        "AQI",
        "PM2.5",
        "PM10",
        "O3"
    ]
    
    var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<5).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
}
