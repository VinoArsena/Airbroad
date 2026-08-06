import Foundation
import CoreLocation

/// Abstraction over wherever AQI numbers actually come from.
/// Swap MockAQIDataService for a real implementation once you've picked a
/// provider (Google Air Quality API, IQAir, OpenWeather Air Pollution API,
/// WAQI, etc). Before you commit to one, verify it actually returns
/// sub-city/neighborhood data for the university towns you care about —
/// most don't, and that's a decision that should happen before more UI
/// gets built on top of it.
protocol AQIDataServing {
    func fetchZones(around center: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [AQIZone]
}

/// Deterministic fake data so the map has something plausible to render
/// while the real data source is still an open question.
struct MockAQIDataService: AQIDataServing {
    func fetchZones(around center: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [AQIZone] {
        let offsets: [(dLat: Double, dLon: Double, aqi: Int, name: String)] = [
            (0.000, 0.000, 42, "Campus Core"),
            (0.010, 0.010, 78, "North District"),
            (-0.010, 0.008, 115, "Industrial Rd Area"),
            (0.008, -0.012, 55, "Riverside"),
            (-0.012, -0.010, 138, "Downtown Interchange")
        ]

        return offsets.map { offset in
            AQIZone(
                name: offset.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: center.latitude + offset.dLat,
                    longitude: center.longitude + offset.dLon
                ),
                radiusMeters: radiusMeters,
                aqi: offset.aqi
            )
        }
    }
}
