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
    
    var maskImage: String {
        switch self {
        case .safe: return "safe"
        case .slight: return "slight"
        case .moderate: return "moderate"
        case .high: return "high"
        }
    }
    
    var headline: String {
        switch self {
        case .safe: return "Air quality is great today"
        case .slight: return "You might feel some discomfort"
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
    
    var calViewModel: CalendarViewModel
    var selectedPollutant: PollutantType = .aqi
    var days: [AirQualityDay] = []
    var isLoading = false
    var errorMessage: String?
    
    // Synced/driven by CalendarViewModel
//    var selectedDate: Date = Calendar.singapore.startOfDay(for: Date())
//    var selectedHourIndex: Int = Calendar.singapore.component(.hour, from: Date())
    
    private let service: AirQualityService
    private let riskPredictor: RiskPredicting?
    private var riskLevelCache: [String: [RiskLevel]] = [:]
    
    private let singaporeLat = 1.35
    private let singaporeLon = 103.82
    
    init(
        calViewModel: CalendarViewModel = CalendarViewModel(),
        service: AirQualityService = AirQualityService(),
        riskPredictor: RiskPredicting? = try? CoreMLRiskPredictor()
    ) {
        self.service = service
        self.riskPredictor = riskPredictor
        self.calViewModel = calViewModel
    }
    
    // MARK: - Selected Day
    var selectedDay: AirQualityDay? {
        days.first { Calendar.singapore.isDate($0.date, inSameDayAs: calViewModel.selectedDate) }
    }
    
    // MARK: - Restored Computed Properties
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
        let riskLevels = mlRiskLevels(for: day)
        
        return (0..<aqiValues.count).map { hour in
            let category = PollutantType.aqi.category(for: aqiValues[hour])
            return RiskDisplayItem(
                time: String(format: "%02d:00", hour),
                category: category,
                riskLevel: riskLevels[safe: hour] ?? RiskLevel(fromCategory: category),
                point: PollutantSnapshot(
                    aqi: aqiValues[safe: hour] ?? 0,
                    pm2_5: pm25Values[safe: hour] ?? 0,
                    pm10: pm10Values[safe: hour] ?? 0,
                    ozone: o3Values[safe: hour] ?? 0
                )
            )
        }
    }
    
    var currentHourData: RiskDisplayItem? {
        let index = Swift.min(Swift.max(calViewModel.actualHour24, 0), results.count - 1)
        return results[safe: index]
    }
    
    var currentRiskLevel: RiskLevel? {
        currentHourData?.riskLevel
    }
    
    var nextBetterTime: String? {
        guard Calendar.singapore.isDateInToday(calViewModel.selectedDate) else { return nil }
        guard let current = currentRiskLevel else { return nil }
        
        let startIndex = Swift.min(Swift.max(calViewModel.actualHour24, 0), results.count - 1)
        guard startIndex + 1 < results.count else { return nil }
        
        let upcoming = results[(startIndex + 1)...]
        return upcoming.first { $0.riskLevel.rawValue < current.rawValue }?.time
    }
    
    var dailySummaryText: String {
        guard let stats = selectedStats, let category = currentCategory else {
                return ""
            }
        
        let comparisonWord = stats.percentVsAverage >= 0 ? "higher" : "lower"
        let percentText = String(format: "%.0f", abs(stats.percentVsAverage))
        let lowestHourText = String(format: "%02d:00", stats.lowestUpcomingHour)
        
        func formatted(_ value: Double) -> String {
            let unit = selectedPollutant.unit
            let number = selectedPollutant == .aqi
            ? String(Int(value.rounded()))
            : String(format: "%.1f", value)
            return unit.isEmpty ? number : "\(number) \(unit)"
        }
        
        switch selectedPollutant {
        case .aqi:
            let advice = category.recommendsStayingIndoors
            ? "not to go out or do outdoor activity"
            : "it's a good time for outdoor activity"
            return """
            Current AQI is \(formatted(stats.current)), you are suggested \(advice).
            Lower AQI expected to be around \(lowestHourText).
            Today's AQI range is from \(formatted(stats.min)) to \(formatted(stats.max)), it will be \(percentText)% \(comparisonWord) than daily average.
            """
            
        case .pm25:
            let advice = category.recommendsStayingIndoors
            ? "sensitive groups should limit prolonged outdoor exertion"
            : "fine particle levels are within a comfortable range"
            return """
            Current PM2.5 is \(formatted(stats.current)), \(advice).
            Cleanest air is expected around \(lowestHourText).
            Today's PM2.5 range is \(formatted(stats.min))–\(formatted(stats.max)), running \(percentText)% \(comparisonWord) than the daily average.
            """
            
        case .pm10:
            let advice = category.recommendsStayingIndoors
            ? "consider keeping windows closed if you're sensitive to dust and pollen"
            : "coarse particle levels look manageable today"
            return """
            Current PM10 is \(formatted(stats.current)), \(advice).
            Levels are expected to ease around \(lowestHourText).
            Today's PM10 range is \(formatted(stats.min))–\(formatted(stats.max)), which is \(percentText)% \(comparisonWord) than the daily average.
            """
            
        case .o3:
            let advice = category.recommendsStayingIndoors
            ? "ground-level ozone is elevated, so heavy outdoor exercise is best postponed"
            : "ozone levels are staying comfortably low"
            return """
            Current O3 is \(formatted(stats.current)), \(advice).
            Ozone is expected to be lowest around \(lowestHourText).
            Today's O3 range is \(formatted(stats.min))–\(formatted(stats.max)), tracking \(percentText)% \(comparisonWord) than the daily average.
            """
        }
    }
    
    var aboutBodyText: String {
        switch selectedPollutant {
        case .aqi:
            return "The Air Quality Index (AQI) is a standardized metric for evaluating air quality that quantifies various pollutants (PM2.5, PM10, O3, etc.) into a single indicator value. Higher values indicate more immediate and severe impacts on respiratory and cardiovascular health, often manifesting within hours or days."
        case .pm25:
            return "PM2.5 consists of fine particulate matter ≤2.5 micrometers. It is highly dangerous because it can penetrate the lung barrier and enter directly into the bloodstream, triggering systemic oxidative stress and acute cardiovascular diseases, including heart failure. Its main sources are combustion residues (such as vehicle emissions and wildfires)."
        case .pm10:
            return "PM10 (inhalable particles ≤10 micrometers) is classified as coarse particulate matter, which includes road dust, pollen, and construction debris. PM10 is typically trapped in the upper respiratory tract, making it a primary cause of acute eye, nose, and throat irritation, and a major trigger for emergency hospital visits among asthma sufferers."
        case .o3:
            return "Ground-level (tropospheric) ozone is a secondary pollutant, unlike the natural stratospheric ozone that protects the earth. It is formed through chemical reactions between nitrogen oxides (NOx) from vehicles/industries and volatile organic compounds (VOCs) in the presence of sunlight. O3 is highly irritating; it inflames the airways, temporarily reduces lung function, and can trigger asthma attacks."
        }
    }
    
    // MARK: - Networking
    func loadInitialLocation() async {
        await self.loadForecast(lat: singaporeLat, lon: singaporeLon)
    }
    
    func loadForecast(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let today = calViewModel.today
        guard let endDate = Calendar.singapore.date(byAdding: .day, value: calViewModel.forecastDaysAhead + 1, to: today) else { return }
        
        do {
            days = try await service.fetchForecast(startDate: today, endDate: endDate, lat: lat, lon: lon)
            riskLevelCache.removeAll()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
            ?? "Couldn't load air quality data. Pull to refresh and try again."
        }
    }
    
    // MARK: - Private Helpers
    private func stats(for values: [Double]) -> Stats? {
        guard !values.isEmpty,
              let minValue = values.min(),
              let maxValue = values.max() else { return nil }
        
        let average = values.reduce(0, +) / Double(values.count)
        let clampedIndex = Swift.min(values.count - 1, Swift.max(0, calViewModel.actualHour24))
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
