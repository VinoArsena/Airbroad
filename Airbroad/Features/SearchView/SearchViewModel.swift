import Foundation
import MapKit
import Combine
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var searchLocationText = ""
    var showBottomPanel: Bool = true
}
