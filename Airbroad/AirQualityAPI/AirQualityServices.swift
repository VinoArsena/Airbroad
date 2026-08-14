
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
    
    var latitude = 1.3573
    var longitude = 103.94

    private let airURL = "https://air-quality-api.open-meteo.com/v1/air-quality"
    private let weatherURL = "https://api.open-meteo.com/v1/forecast"
    private let timeZoneIdentifier = "Asia/Singapore"

    
    func fetchForecast(startDate: Date, endDate: Date, lat: Double, lon: Double) async throws -> [AirQualityDay] {
        guard let airReqUrl = buildURLPollutant(startDate: startDate, endDate: endDate, lat: lat, lon: lon), let weatherReqUrl = buildURLWeather(startDate: startDate, endDate: endDate, lat: lat, lon: lon) else {
            throw AirQualityServiceError.invalidURL
        }

        let (airData, airResponse) = try await URLSession.shared.data(from: airReqUrl)
        let (weatherData, weatherResponse) = try await URLSession.shared.data(from: weatherReqUrl)

        let decoder = JSONDecoder()
        let decodedAir: PollutantResponse
        let decodedWeather: WeatherResponse
        
        do {
            decodedAir = try decoder.decode(PollutantResponse.self, from: airData)
            decodedWeather = try decoder.decode(WeatherResponse.self, from: weatherData)
        } catch {
            throw AirQualityServiceError.decodingFailed(error)
        }

        return Self.groupByDay(air: decodedAir.hourly, weather: decodedWeather.hourly, timeZoneIdentifier: timeZoneIdentifier)
    }

    private func buildURLPollutant(startDate: Date, endDate: Date, lat: Double, lon: Double) -> URL? {
        var components = URLComponents(string: airURL)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "start_date", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "end_date", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "hourly", value: "us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,ozone"),
            URLQueryItem(name: "timezone", value: timeZoneIdentifier)
        ]

        return components?.url
    }
    
    private func buildURLWeather(startDate: Date, endDate: Date, lat: Double, lon: Double) -> URL? {
        var components = URLComponents(string: weatherURL)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier)

        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "start_date", value: dateFormatter.string(from: startDate)),
            URLQueryItem(name: "end_date", value: dateFormatter.string(from: endDate)),
            URLQueryItem(name: "hourly", value: "temperature_2m, relative_humidity_2m, wind_speed_10m, rain"),
            URLQueryItem(name: "timezone", value: timeZoneIdentifier)
        ]

        return components?.url
    }

    // grouping per day buat date picker
    private static func groupByDay(air: PollutantHourly, weather: WeatherHourly, timeZoneIdentifier: String) -> [AirQualityDay] {
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
            var co: [Double] = []
            var no2: [Double] = []
            var o3: [Double] = []
            var temp: [Double] = []
            var humidity: [Double] = []
            var windSpeed: [Double] = []
            var rain: [Double] = []
        }

        var buckets: [String: Bucket] = [:]
        var order: [String] = []

        for (index, timeString) in air.time.enumerated() {
            guard let timestamp = timeFormatter.date(from: timeString) else { continue }
            let dayKey = dayKeyFormatter.string(from: timestamp)
            
            if buckets[dayKey] == nil {
                buckets[dayKey] = Bucket(date: timestamp)
                order.append(dayKey)
            }
            
            buckets[dayKey]?.aqi.append(value(air.us_aqi, at: index))
            buckets[dayKey]?.pm25.append(value(air.pm2_5, at: index))
            buckets[dayKey]?.pm10.append(value(air.pm10, at: index))
            buckets[dayKey]?.o3.append(value(air.ozone, at: index))
            buckets[dayKey]?.co.append(value(air.carbon_monoxide, at: index))
            buckets[dayKey]?.no2.append(value(air.nitrogen_dioxide, at: index))
            buckets[dayKey]?.o3.append(value(air.ozone, at: index))
            
            buckets[dayKey]?.temp.append(value(weather.temperature_2m, at: index))
            buckets[dayKey]?.humidity.append(value(weather.relative_humidity_2m, at: index))
            buckets[dayKey]?.windSpeed.append(value(weather.wind_speed_10m, at: index))
            buckets[dayKey]?.rain.append(value(weather.rain, at: index))
        }

        return order.compactMap { key in
            guard let bucket = buckets[key] else { return nil }
            return AirQualityDay(
                id: key,
                date: bucket.date,
                hourlyAQI: bucket.aqi,
                hourlyPM25: bucket.pm25,
                hourlyPM10: bucket.pm10,
                hourlyCO: bucket.co,
                hourlyNO2: bucket.no2,
                hourlyO3: bucket.o3,
                minAQI: bucket.aqi.min() ?? 0,
                maxAQI: bucket.aqi.max() ?? 0,
                hourlyTemperature: bucket.temp,
                hourlyHumidity: bucket.humidity,
                hourlyWindSpeed: bucket.windSpeed,
                hourlyRain: bucket.rain
            )
        }
    }
}

// kalau ada null val
private func value(_ array: [Double?], at index: Int) -> Double {
    guard array.indices.contains(index) else { return 0 }
    return array[index] ?? 0
}
