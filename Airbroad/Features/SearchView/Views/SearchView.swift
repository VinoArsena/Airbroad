import SwiftUI
import MapKit

struct SearchView: View {
    @Bindable var viewModel = SearchViewModel()
    
    @State var currentPresentationDetents: PresentationDetent = .fraction(0.3)
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.3048, longitude: 103.8318),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        ZStack{
            Map(position: $position)
        }
        .sheet(isPresented: $viewModel.showBottomPanel) {
            BottomPanelSheetView(viewModel: viewModel, currentPresentationDetents: $currentPresentationDetents)
                .presentationDetents([.fraction(0.3), .large], selection: $currentPresentationDetents)
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    SearchView()
}
