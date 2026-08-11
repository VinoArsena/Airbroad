import SwiftUI

struct BottomPanelSheetView: View {
    @Bindable var viewModel: SearchViewModel
    @Binding var currentPresentationDetents: PresentationDetent
    
    @FocusState private var textFieldClicked: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.trailing, 5)
                
                TextField("Where you wanna go?", text: $viewModel.locationSearch)
                    .focused($textFieldClicked)
                    .onChange(of: viewModel.locationSearch) { _, newQuery in
                        let isSelectedTitle = viewModel.selectedDestination?.title == newQuery
                        
                        if textFieldClicked && !newQuery.isEmpty && !isSelectedTitle {
                            currentPresentationDetents = .large
                            viewModel.searchLocation(query: newQuery)
                        }
                    }
            }
            .padding(10)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            if textFieldClicked {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.locationSearchResults.prefix(5), id: \.self) { result in
                            LocationSuggestionView(
                                viewModel: viewModel,
                                currentPresentationDetents: $currentPresentationDetents,
                                textFieldClicked: $textFieldClicked,
                                result: result
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("How long will you stay?")
                .font(.callout)
                .fontWeight(.bold)
                .padding(.top, 5)
            
            VStack {
                HStack {
                    Text("Starts")
                    Spacer()
                    
                    Text(viewModel.startDatePicked, format: .dateTime.day().month(.wide).year())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                    
                    Text(viewModel.startDatePicked, format: .dateTime.hour().minute())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
                .overlay(
                    DatePicker("", selection: $viewModel.startDatePicked, displayedComponents: [.date, .hourAndMinute])
                        .blendMode(.destinationOver)
                )
                
                Divider()
                
                HStack {
                    Text("Ends")
                    Spacer()
                    
                    Text(viewModel.endDatePicked, format: .dateTime.day().month(.wide).year())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                    
                    Text(viewModel.endDatePicked, format: .dateTime.hour().minute())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
                .padding(.top, 2)
                .overlay(
                    DatePicker("", selection: $viewModel.endDatePicked, displayedComponents: [.date, .hourAndMinute])
                        .blendMode(.destinationOver)
                )
            }
            .padding(10)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onChange(of: viewModel.selectedDestination?.id) { _, _ in
            textFieldClicked = false
            withAnimation {
                currentPresentationDetents = .fraction(0.3)
            }
        }
    }
}
