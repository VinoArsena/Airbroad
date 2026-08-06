import SwiftUI
import MapKit

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $viewModel.cameraPosition) {
                    ForEach(viewModel.zones) { zone in
                        MapCircle(center: zone.coordinate, radius: zone.radiusMeters)
                            .foregroundStyle(zone.category.color.opacity(0.35))
                            .stroke(zone.category.color, lineWidth: 2)

                        Annotation(zone.name, coordinate: zone.coordinate) {
                            Button {
                                viewModel.selectedZone = zone
                            } label: {
                                Text("\(zone.aqi)")
                                    .font(.caption).bold()
                                    .padding(6)
                                    .background(zone.category.color)
                                    .clipShape(Circle())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .mapStyle(.standard)

                VStack {
                    searchBar
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.red.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                    }
                    Spacer()
                    if let zone = viewModel.selectedZone {
                        zoneCard(zone)
                    }
                }
            }
            .navigationTitle("Air Quality Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search university (e.g. \"UCLA\")", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.searchUniversity() }
                }
            if viewModel.isSearching {
                ProgressView()
            }
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func zoneCard(_ zone: AQIZone) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(zone.name).font(.headline)
                Spacer()
                Text(zone.category.rawValue)
                    .font(.caption).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(zone.category.color)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Text("AQI \(zone.aqi) · dominant pollutant \(zone.dominantPollutant)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Next two steps in your flow chart hang off this.
            NavigationLink("View accommodation & forecast") {
                Text("Accommodation list for \(zone.name) — TODO")
            }
            .font(.footnote)
        }
        .padding()
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
    }
}

#Preview {
    MainView()
}
