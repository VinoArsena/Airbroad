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
        ZStack (alignment: .top){
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {viewModel.showSearchBar = true}) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                        
                        if (viewModel.locationSearchResults == [] || viewModel.selectedDestination == nil) {
                            Text("Where")
                                .foregroundStyle(Color(.systemGray))
                                .font(.headline)
                        } else {
                            Text("\(viewModel.locationSearch)")
                            .font(.headline)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.title3)
                    }
                    
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 10)
                    
                    Button(action: {}) {
                        Image(systemName: "calendar")
                        
                        Text("When")
                            .foregroundStyle(Color(.systemGray))
                            .font(.headline)
                        
                        Image(systemName: "chevron.down")
                    }
                    
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassEffect(.regular.tint(Color(.systemGroupedBackground)))
                
                SearchBarView(viewModel: viewModel)
                    .padding(.top, 10)
                    .opacity(viewModel.showSearchBar ? 1 : 0)
                
                Spacer()
                
                VStack (alignment: .leading) {
                    
                    HStack {
                        VStack (alignment: .leading) {
                            Text(viewModel.selectedDestination?.title ?? "Singapore")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Today")
                                .font(.body)
                                .foregroundStyle(Color(.systemGray))
                        }
                        
                        Spacer()
                        
                        Text(  viewModel.currentTime).font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Slider(
                        value: $viewModel.sliderTime,
                        in: 0...23,
                        step: 1,
                        label: { Text("Time") },
                        tick: { value in
                            SliderTick(value) {
                                if Int(value) == Calendar.current.component(.hour, from: Date()) {
                                    Text("Now")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                } else if Int(value) % 2 == 1 {
                                    Text(String(format: "%02d", Int(value)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        },
                        onEditingChanged: { editing in
                            viewModel.isEditing = editing
                        }
                    )
                }
                .padding(20)
                .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
                
                
            }
            
            .padding(.horizontal, 20)
            
            
        }
    }
}

#Preview {
    SearchView()
}
