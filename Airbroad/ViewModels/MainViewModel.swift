import Foundation
import _MapKit_SwiftUI
import MapKit
import Combine

@MainActor
final class MainViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var zones: [AQIZone] = []
    @Published var selectedZone: AQIZone?
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    private let aqiService: AQIDataServing

    init(aqiService: AQIDataServing = MockAQIDataService()) {
        self.aqiService = aqiService
    }

    func searchUniversity() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        selectedZone = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // Not restricting resultTypes here on purpose — some campuses geocode
        // as addresses rather than points of interest, and restricting too
        // early just produces false "no results" for a real place.

        do {
            // NOTE: if ⁠ .start() ⁠ has no async overload on your SDK, replace
            // this do-block with:
            //   try await withCheckedThrowingContinuation { continuation in
            //       MKLocalSearch(request: request).start { response, error in
            //           if let error { continuation.resume(throwing: error) }
            //           else if let response { continuation.resume(returning: response) }
            //       }
            //   }
            let response = try await MKLocalSearch(request: request).start()

            guard let firstResult = response.mapItems.first else {
                errorMessage = "No results for \"\(query)\". Try adding the city."
                return
            }

            let coordinate = firstResult.placemark.coordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )

            zones = try await aqiService.fetchZones(around: coordinate, radiusMeters: 600)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }
}
