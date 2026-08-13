//
//  AirQualityModels.swift
//  Airbroad
//
//  Created by Elena Nathanielle on 13/08/26.
//

import Foundation

struct AirQualityDay: Codable, Identifiable {
    let id: String
    let date: Date

    let hourlyAQI: [Double]
    let hourlyPM25: [Double]
    let hourlyPM10: [Double]
    let hourlyO3: [Double]

    let minAQI: Double
    let maxAQI: Double
}

struct OpenMeteoResponse: Codable {
    let hourly: HourlyData
}

struct HourlyData: Codable {
    let time: [String]

    let us_aqi: [Double?]
    let pm2_5: [Double?]
    let pm10: [Double?]
    let carbon_monoxide: [Double?]?
    let nitrogen_dioxide: [Double?]?
    let ozone: [Double?]
}


enum PollutantType: String, CaseIterable, Identifiable {
    case aqi
    case pm25
    case pm10
    case o3

    var id: String { rawValue }

    var tabTitle: String {
        switch self {
        case .aqi:  return "AQI"
        case .pm25: return "PM2.5"
        case .pm10: return "PM10"
        case .o3:   return "O3"
        }
    }

    var unit: String {
        switch self {
        case .aqi:  return ""
        case .pm25, .pm10, .o3: return "µg/m³"
        }
    }

    // ini define sndiri lagi ntar
    func category(for value: Double) -> AQICategory {
        switch self {
        case .aqi:
            return AQICategory.forAQI(value)
        case .pm25:
            switch value {
            case ..<12:      return .low
            case 12..<35.5:  return .moderate
            case 35.5..<55.5: return .high
            case 55.5..<150.5: return .veryHigh
            default:         return .extreme
            }
        case .pm10:
            switch value {
            case ..<55:   return .low
            case 55..<155: return .moderate
            case 155..<255: return .high
            case 255..<355: return .veryHigh
            default:      return .extreme
            }
        case .o3:
            switch value {
            case ..<100:  return .low
            case 100..<160: return .moderate
            case 160..<215: return .high
            case 215..<265: return .veryHigh
            default:      return .extreme
            }
        }
    }
}


// idk ini perlu/ga
enum AQICategory: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case extreme = "Extreme"

    static func forAQI(_ value: Double) -> AQICategory {
        switch value {
        case ..<51:   return .low
        case 51..<101: return .moderate
        case 101..<151: return .high
        case 151..<201: return .veryHigh
        default:      return .extreme
        }
    }


    var recommendsStayingIndoors: Bool {
        switch self {
        case .low, .moderate: return false
        case .high, .veryHigh, .extreme: return true
        }
    }
}
