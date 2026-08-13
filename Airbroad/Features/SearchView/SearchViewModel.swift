import Foundation
import MapKit
import Combine
import Observation

@MainActor
@Observable
final class SearchViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var showSearchBar: Bool = false
    
    var locationSearch: String = ""
    var datePicked = Date()
    var locationSearchResults: [MKLocalSearchCompletion] = []
    var selectedDestination: NavigationDestination?
    
    var isEditing = false
    
    var sliderTime: Double = Double(Calendar.current.component(.hour, from: Date()))
    var currentTime: String {
        String(format: "%02.0f.00", sliderTime)
    }
    
    
    private let completer = MKLocalSearchCompleter()

    
    /// Search Completer
    override init() {
        super.init()
        initSearchCompleter()
    }
    
    func initSearchCompleter() {
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        
        let singaporeCenter = CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)
        completer.region = MKCoordinateRegion(
            center: singaporeCenter,
            latitudinalMeters: 50_000,
            longitudinalMeters: 50_000
        )
    }
    
    @MainActor
    func selectCompletion(_ completion: MKLocalSearchCompletion) async {
        if let destination = await resolveDestination(for: completion) {
            self.selectedDestination = destination
            self.locationSearch = destination.title
            
            self.locationSearchResults = []
        }
    }
    
    @MainActor
    func resolveDestination(for completion: MKLocalSearchCompletion) async -> NavigationDestination? {
        let request = MKLocalSearch.Request(completion: completion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let coordinate = response.mapItems.first?.placemark.coordinate else { return nil }
            return NavigationDestination(coordinate: coordinate, title: completion.title)
        } catch {
            return nil
            
        }
    }
    
    func searchLocation(query: String) {
        if let selected = selectedDestination, selected.title == query {
            return
        }
        
        guard !query.isEmpty else {
            locationSearchResults = []
            return
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms debounce
            guard !Task.isCancelled else { return }
            completer.queryFragment = query
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        locationSearchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        locationSearchResults = []
    }

}



struct NavigationDestination: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}
