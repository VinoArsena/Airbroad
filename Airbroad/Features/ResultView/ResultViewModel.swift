//
//  ResultViewModel.swift
//  Airbroad
//
//  Created by Elena Nathanielle on 13/08/26.
//

import Foundation
import Observation
import Foundation

@Observable
class ResultViewModel {

    var selectedDate: Date
    var selectedPollutant: PollutantType = .aqi
    var days: [AirQualityDay] = []
    var isLoading = false
    var errorMessage: String?

    private let service: AirQualityService
    private let calendar: Calendar

    // How many days ahead the API is asked for
    private let forecastDaysAhead = 4

    init(service: AirQualityService = AirQualityService()) {
        self.service = service

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Singapore") ?? .current
        self.calendar = cal
        self.selectedDate = cal.startOfDay(for: Date())
    }


    func loadForecast() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let today = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: forecastDaysAhead, to: today) else { return }

        do {
            days = try await service.fetchForecast(startDate: today, endDate: endDate)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't load air quality data. Pull to refresh and try again."
        }
    }


    var availableDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0...forecastDaysAhead).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
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

    var currentHourIndex: Int {
        calendar.component(.hour, from: Date())
    }

    struct Stats {
        let current: Double
        let min: Double
        let max: Double
        let average: Double
        let percentVsAverage: Double
        let lowestUpcomingHour: Int
    }

    private func stats(for values: [Double]) -> Stats? {
        guard !values.isEmpty,
              let minValue = values.min(),
              let maxValue = values.max() else { return nil }

        let average = values.reduce(0, +) / Double(values.count)
        let clampedIndex = Swift.min(values.count - 1, Swift.max(0, currentHourIndex))
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
}
