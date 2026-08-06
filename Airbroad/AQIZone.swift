import Foundation
import CoreLocation
import SwiftUI

/// A discrete area around a university with its own air quality reading.
/// NOTE: whether this is a real polygon, an interpolated grid cell, or just
/// "the nearest station's number copy-pasted three times" depends entirely
/// on which AQI provider you pick. See AQIDataService.swift.
struct AQIZone: Identifiable, Hashable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let radiusMeters: Double
    let aqi: Int
    let dominantPollutant: String

    var category: AQICategory {
        AQICategory(aqi: aqi)
    }

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double = 500,
        aqi: Int,
        dominantPollutant: String = "PM2.5"
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.radiusMeters = radiusMeters
        self.aqi = aqi
        self.dominantPollutant = dominantPollutant
    }

    // CLLocationCoordinate2D isn't reliably Hashable across SDK versions,
    // so equality/hashing is based on id only.
    static func == (lhs: AQIZone, rhs: AQIZone) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// test

/// Standard US EPA AQI breakpoints.
/// Worth knowing for a COPD-focused app: the EPA explicitly calls out "people
/// with heart or lung disease" as a sensitive group starting at the ORANGE
/// tier (101+), not just at the general-population RED tier (151+). If your
/// UI only warns at 151+, it's under-warning the exact user you're building for.
enum AQICategory: String, CaseIterable {
    case good = "Good"
    case moderate = "Moderate"
    case sensitiveUnhealthy = "Unhealthy for Sensitive Groups"
    case unhealthy = "Unhealthy"
    case veryUnhealthy = "Very Unhealthy"
    case hazardous = "Hazardous"

    init(aqi: Int) {
        switch aqi {
        case ..<51: self = .good
        case 51..<101: self = .moderate
        case 101..<151: self = .sensitiveUnhealthy
        case 151..<201: self = .unhealthy
        case 201..<301: self = .veryUnhealthy
        default: self = .hazardous
        }
    }

    var color: Color {
        switch self {
        case .good: return .green
        case .moderate: return .yellow
        case .sensitiveUnhealthy: return .orange
        case .unhealthy: return .red
        case .veryUnhealthy: return .purple
        case .hazardous: return .brown
        }
    }
}
