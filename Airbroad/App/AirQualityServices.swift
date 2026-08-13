//
//  AirQualityService.swift
//  Airbroad
//
//  Created by Elena Nathanielle on 13/08/26.
//

import Foundation

enum AirQualityServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    
    // debug error
    var errorDescription: String? {
        switch self {
        case .invalidURL:      return "Couldn't build the request URL."
        case .invalidResponse: return "The server returned an unexpected response."
        case .decodingFailed(let underlying):
            return "Couldn't read the air quality data. (\(underlying.localizedDescription))"
        }
    }
}


struct AirQualityService {

    private let baseURL = "https://air-quality-api.open-meteo.com/v1/air-quality"

    // ini location nya ntar based on user input kan ya?
    private let latitude = 1.3573
    private let longitude = 103.94

    private let timeZoneIdentifier = "Asia/Singapore"

    
    func fetchForecast(startDate: Date, endDate: Date) async throws -> [AirQualityDay] {
        guard let url = buildURL(startDate: startDate, endDate: endDate) else {
            throw AirQualityServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AirQualityServiceError.invalidResponse
        }

        let decoded: OpenMeteoResponse
        do {
            decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        } catch {
            throw AirQualityServiceError.decodingFailed(error)
        }

        return Self.groupByDay(decoded.hourly, timeZoneIdentifier: timeZoneIdentifier)
    }

    private func buildURL(startDate: Date, endDate: Date) -> URL? {
        var components = URLComponents(string: baseURL)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "start_date", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "end_date", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "hourly", value: "us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,ozone"),
            URLQueryItem(name: "timezone", value: timeZoneIdentifier)
        ]

        return components?.url
    }

    // grouping per day buat date picker
    private static func groupByDay(_ hourly: HourlyData, timeZoneIdentifier: String) -> [AirQualityDay] {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        timeFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        let dayKeyFormatter = DateFormatter()
        dayKeyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayKeyFormatter.dateFormat = "yyyy-MM-dd"
        dayKeyFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        struct Bucket {
            var date: Date
            var aqi: [Double] = []
            var pm25: [Double] = []
            var pm10: [Double] = []
            var o3: [Double] = []
        }

        var buckets: [String: Bucket] = [:]
        var order: [String] = []

        for (index, timeString) in hourly.time.enumerated() {
            guard let timestamp = timeFormatter.date(from: timeString) else { continue }
            let dayKey = dayKeyFormatter.string(from: timestamp)

            if buckets[dayKey] == nil {
                buckets[dayKey] = Bucket(date: timestamp)
                order.append(dayKey)
            }

            buckets[dayKey]?.aqi.append(value(hourly.us_aqi, at: index))
            buckets[dayKey]?.pm25.append(value(hourly.pm2_5, at: index))
            buckets[dayKey]?.pm10.append(value(hourly.pm10, at: index))
            buckets[dayKey]?.o3.append(value(hourly.ozone, at: index))
        }

        return order.compactMap { key in
            guard let bucket = buckets[key] else { return nil }
            return AirQualityDay(
                id: key,
                date: bucket.date,
                hourlyAQI: bucket.aqi,
                hourlyPM25: bucket.pm25,
                hourlyPM10: bucket.pm10,
                hourlyO3: bucket.o3,
                minAQI: bucket.aqi.min() ?? 0,
                maxAQI: bucket.aqi.max() ?? 0
            )
        }
    }
}

// kalau ada null val
private func value(_ array: [Double?], at index: Int) -> Double {
    guard array.indices.contains(index) else { return 0 }
    return array[index] ?? 0
}
