import SwiftUI

struct SearchBarView: View {
    @Bindable var viewModel: SearchViewModel
    
    @FocusState private var textFieldClicked: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.trailing, 5)
                
                TextField("Where", text: $viewModel.locationSearch).focused($textFieldClicked)
                    .onChange(of: viewModel.locationSearch) { _, newQuery in
                        let isSelectedTitle = viewModel.selectedDestination?.title == newQuery
                        
                        if textFieldClicked && !newQuery.isEmpty && !isSelectedTitle {
                            viewModel.searchLocation(query: newQuery)
                        }
                    }
                    .onAppear {
                        textFieldClicked = true
                    }
            }
            .padding(10)
            .glassEffect(.regular.tint(Color(.secondarySystemGroupedBackground)))
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, viewModel.locationSearch == "" ? 15 : 5)
            
            if viewModel.locationSearch != "" {
                VStack(spacing: 0) {
                    ForEach(viewModel.locationSearchResults.prefix(3), id: \.self) { result in
                        LocationSuggestionView(
                            viewModel: viewModel,
                            textFieldClicked: $textFieldClicked,
                            result: result
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    }
                    
                }
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        .padding(.horizontal, 15)
    }
}

#Preview {
    SearchBarView(viewModel: SearchViewModel())
}
