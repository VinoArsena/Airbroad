import Foundation
import Observation

struct PollutantSnapshot {
    let aqi: Double
    let pm2_5: Double
    let pm10: Double
    let ozone: Double
}

struct RiskDisplayItem: Identifiable {
    let id = UUID()
    let time: String
    let category: AQICategory
    let riskLevel: RiskLevel
    let point: PollutantSnapshot
}

enum RiskLevel: Int, CaseIterable {
    case safe = 0, slight = 1, moderate = 2, high = 3
    
    init(fromCategory category: AQICategory) {
        switch category {
        case .low: self = .safe
        case .moderate: self = .slight
        case .high: self = .moderate
        case .veryHigh, .extreme: self = .high
        }
    }

    init?(mlLabel: String) {
        switch mlLabel {
        case "Safe": self = .safe
        case "Slight Risk": self = .slight
        case "Moderate Risk": self = .moderate
        case "High Risk": self = .high
        default: return nil
        }
    }
    
    var headline: String {
        switch self {
        case .safe: return "Air quality is great today"
        case .slight: return "You might feet some discomfort"
        case .moderate: return "Take extra precaution"
        case .high: return "High risk, avoid going outside"
        }
    }
    
    var recommendation: String {
        switch self {
        case .safe: return "Enjoy your time outdoors."
        case .slight: return "You are suggested to wear and bring your mask."
        case .moderate: return "Limit outdoor activity and keep your inhaler nearby."
        case .high: return "Stay indoors as much as possible. Keep rescue medication accessible."
        }
    }
}

@Observable
class ResultViewModel {
    struct Stats {
        let current: Double
        let min: Double
        let max: Double
        let average: Double
        let percentVsAverage: Double
        let lowestUpcomingHour: Int
    }
    
    var selectedDate: Date
    var selectedPollutant: PollutantType = .aqi
    var days: [AirQualityDay] = []
    var isLoading = false
    var errorMessage: String?
    
    init(
        service: AirQualityService = AirQualityService(),
        riskPredictor: RiskPredicting? = try? CoreMLRiskPredictor()
    ) {
        self.service = service
        self.riskPredictor = riskPredictor
        
        let cal = Calendar.current
        self.calendar = cal
        
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let today = cal.date(from: components) ?? cal.startOfDay(for: Date())
        self.selectedDate = today
    }
    
    var availableDates: [Date] {
        let today = startOfTodayInTargetTimeZone
        return (0...forecastDaysAhead).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }
    
    var selectedStats: Stats? {
        guard let day = selectedDay else { return nil }
        return stats(for: hourlyValues(for: day, pollutant: selectedPollutant))
    }
    
    var aqiStats: Stats? {
        guard let day = selectedDay else { return nil }
        return stats(for: day.hourlyAQI)
    }
    
    var pm25Stats: Stats? {
        guard let day = selectedDay else { return nil }
        return stats(for: day.hourlyPM25)
    }
    
    var pm10Stats: Stats? {
        guard let day = selectedDay else { return nil }
        return stats(for: day.hourlyPM10)
    }
    
    var currentCategory: AQICategory? {
        guard let value = selectedStats?.current else { return nil }
        return selectedPollutant.category(for: value)
    }
    
    var chartValues: [Double] {
        guard let day = selectedDay else { return [] }
        return hourlyValues(for: day, pollutant: selectedPollutant)
    }
    
    var results: [RiskDisplayItem] {
        guard let day = selectedDay else { return [] }
        
        let aqiValues = day.hourlyAQI
        let pm25Values = day.hourlyPM25
        let pm10Values = day.hourlyPM10
        let o3Values = day.hourlyO3
        
        let startIndex = Swift.min(selectedHourIndex, aqiValues.count - 1)
        
        guard startIndex >= 0, startIndex < aqiValues.count else { return [] }
        
        let riskLevels = mlRiskLevels(for: day)
        
        var items: [RiskDisplayItem] = []
        items.reserveCapacity(aqiValues.count)
        
        for hour in 0..<aqiValues.count {
            let category = PollutantType.aqi.category(for: aqiValues[hour])
            let item = RiskDisplayItem(
                time: timeLabel(forHour: hour),
                category: category,
                riskLevel: riskLevels[safe: hour] ?? RiskLevel(fromCategory: category),
                point: PollutantSnapshot(
                    aqi: aqiValues[safe: hour] ?? 0,
                    pm2_5: pm25Values[safe: hour] ?? 0,
                    pm10: pm10Values[safe: hour] ?? 0,
                    ozone: o3Values[safe: hour] ?? 0)
            )
            items.append(item)
        }
        
        return items
    }
    
    var currentHourData: RiskDisplayItem? {
        let index = Swift.min(Swift.max(selectedHourIndex, 0), results.count - 1)
        return results[safe: index]
    }
    
    var currentRiskLevel: RiskLevel? {
        currentHourData?.riskLevel
    }
    
    var nextBetterTime: String? {
        guard calendar.isDateInToday(selectedDate) else { return nil }
        guard let current = currentRiskLevel else { return nil }
        
        let startIndex = Swift.min(Swift.max(selectedHourIndex, 0), results.count - 1)
        let upcoming = results[(startIndex + 1)...]   // only look forward from selected hour, not from hour 0
        
        for item in upcoming {
            if item.riskLevel.rawValue < current.rawValue {
                return item.time
            }
        }
        return nil
    }
    
    func loadInitialLocation() async {
        await self.loadForecast(lat: singaporeLat, lon: singaporeLon)
    }
    
    func loadForecast(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let today = startOfTodayInTargetTimeZone
        guard let endDate = calendar.date(byAdding: .day, value: forecastDaysAhead + 1, to: today) else { return }
        
        do {
            days = try await service.fetchForecast(startDate: today, endDate: endDate, lat: lat, lon: lon)
            riskLevelCache.removeAll()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
            ?? "Couldn't load air quality data. Pull to refresh and try again."
        }
    }
    
    func isSelectable(_ date: Date) -> Bool {
        availableDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    func select(date: Date) {
        guard isSelectable(date) else { return }
        selectedDate = calendar.startOfDay(for: date)
    }
    
    var selectedDay: AirQualityDay? {
        days.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var selectedHourIndex: Int = Calendar.current.component(.hour, from: Date())
    
    private let singaporeLat = 1.35
    private let singaporeLon = 103.82
    
    private let service: AirQualityService
    private let calendar: Calendar
    private let riskPredictor: RiskPredicting?
    
    private var riskLevelCache: [String: [RiskLevel]] = [:]
    
    private let forecastDaysAhead = 3
    
    private var startOfTodayInTargetTimeZone: Date {
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return calendar.date(from: components) ?? calendar.startOfDay(for: Date())
    }
    
    private func stats(for values: [Double]) -> Stats? {
        guard !values.isEmpty,
              let minValue = values.min(),
              let maxValue = values.max() else { return nil }
        
        let average = values.reduce(0, +) / Double(values.count)
        let clampedIndex = Swift.min(values.count - 1, Swift.max(0, selectedHourIndex))
        let current = values[clampedIndex]
        let percent = average == 0 ? 0 : ((current - average) / average) * 100
        
        let upcoming = values.enumerated().filter { $0.offset >= clampedIndex }
        let searchSpace = upcoming.isEmpty ? Array(values.enumerated()) : upcoming
        let lowestHour = searchSpace.min(by: { $0.element < $1.element })?.offset ?? clampedIndex
        
        return Stats(
            current: current,
            min: minValue,
            max: maxValue,
            average: average,
            percentVsAverage: percent,
            lowestUpcomingHour: lowestHour
        )
    }
    
    private func hourlyValues(for day: AirQualityDay, pollutant: PollutantType) -> [Double] {
        switch pollutant {
        case .aqi:  return day.hourlyAQI
        case .pm25: return day.hourlyPM25
        case .pm10: return day.hourlyPM10
        case .o3:   return day.hourlyO3
        }
    }
    
    private func timeLabel(forHour hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
    
    private func mlRiskLevels(for day: AirQualityDay) -> [RiskLevel] {
        if let cached = riskLevelCache[day.id] {
            return cached
        }
        
        let levels = (0..<day.hourlyAQI.count).map { hour -> RiskLevel in
            let fallbackCategory = PollutantType.aqi.category(for: day.hourlyAQI[safe: hour] ?? 0)
            let fallback = RiskLevel(fromCategory: fallbackCategory)
            
            guard let riskPredictor else { return fallback }
            
            do {
                let prediction = try riskPredictor.predict(
                    pm2_5: day.hourlyPM25[safe: hour] ?? 0,
                    pm10: day.hourlyPM10[safe: hour] ?? 0,
                    carbonMonoxide: day.hourlyCO[safe: hour] ?? 0,
                    nitrogenDioxide: day.hourlyNO2[safe: hour] ?? 0,
                    ozone: day.hourlyO3[safe: hour] ?? 0,
                    temperature: day.hourlyTemperature[safe: hour] ?? 0,
                    humidity: day.hourlyHumidity[safe: hour] ?? 0,
                    windSpeed: day.hourlyWindSpeed[safe: hour] ?? 0,
                    rain: day.hourlyRain[safe: hour] ?? 0
                )
                return prediction.riskLevel ?? fallback
            } catch {
                return fallback
            }
        }
        
        riskLevelCache[day.id] = levels
        return levels
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
