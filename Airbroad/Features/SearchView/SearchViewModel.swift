import Foundation
import MapKit
import Combine
import Observation

@MainActor
@Observable
final class SearchViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var showSearchBar: Bool = false
    var showCalendar: Bool = false
    
    enum ActivePicker { case none, location, date }
    var activePicker: ActivePicker = .none
    
    var locationSearch: String = ""
    var pickedDate: Date = Date()
    var locationSearchResults: [MKLocalSearchCompletion] = []
    var selectedDestination: NavigationDestination?
    
    var isEditing = false
    
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
            self.showSearchBar = false
            self.activePicker = .none
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

@Observable
final class KeyboardObserver {
    var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map(\.height)
            .sink { [weak self] in self?.height = $0 }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.height = 0 }
            .store(in: &cancellables)
    }
}

struct NavigationDestination: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}
