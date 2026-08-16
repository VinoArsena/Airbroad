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

    var minSelectableDate: Date {
        Calendar.singapore.startOfDay(for: Date())
    }
    var maxSelectableDate: Date {
        Calendar.singapore.date(byAdding: .day, value: 3, to: minSelectableDate) ?? Date()
    }
    
    // MARK: - Time picker
    // KONSEP: slider CUMA merepresentasikan posisi jam di angka 12-jam
    // (0 = "12", 1..11 = "1".."11") -- TIDAK menentukan AM/PM sama sekali.
    var sliderHour12: Double = {
        let h24 = Calendar.singapore.component(.hour, from: Date())
        return Double(h24 % 12)
    }()

    // KONSEP: ini variabel TERPISAH, cuma diubah oleh SunMoonToggle --
    // tidak pernah dihitung ulang dari slider.
    var isPM: Bool = Calendar.singapore.component(.hour, from: Date()) >= 12

    // Nilai 24-jam sesungguhnya, digabung dari KEDUA variabel di atas.
    var actualHour24: Int {
        let displayedHour12 = Int(sliderHour12) == 0 ? 12 : Int(sliderHour12)
        if isPM {
            return displayedHour12 == 12 ? 12 : displayedHour12 + 12
        } else {
            return displayedHour12 == 12 ? 0 : displayedHour12
        }
    }

    var currentTime12Hour: String {
        let displayedHour12 = Int(sliderHour12) == 0 ? 12 : Int(sliderHour12)
        return String(format: "%d:00 %@", displayedHour12, isPM ? "PM" : "AM")
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



struct NavigationDestination: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}
