import SwiftUI
import MapKit

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showingDatePicker = false
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?

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
                    dateFilterBar
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
        .sheet(isPresented: $showingDatePicker) {
            EventDateRangePicker { start, end in
                selectedStartDate = start
                selectedEndDate = end
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var dateFilterBar: some View {
        Button {
            showingDatePicker = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text(dateRangeLabel)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundStyle(.primary)
            .padding(10)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var dateRangeLabel: String {
        guard let start = selectedStartDate else { return "Select move-in dates" }
        guard let end = selectedEndDate else {
            return start.formatted(.dateTime.month().day())
        }
        return "\(start.formatted(.dateTime.month().day())) – \(end.formatted(.dateTime.month().day()))"
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
