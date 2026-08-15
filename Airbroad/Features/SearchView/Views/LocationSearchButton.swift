
import SwiftUI

struct LocationSearchButton: View {
    @Bindable var viewModel: SearchViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var hasSelectedLocation: Bool {
        viewModel.selectedDestination != nil
    }
    
    private var foregroundColor: Color {
            colorScheme == .dark ? .white : .black
        }
    
    /// <#Description#>
    var body: some View {
        Button {
            if (viewModel.showSearchBar == true) {
                viewModel.showSearchBar = false
                viewModel.activePicker = .none
            } else {
                viewModel.showSearchBar = true
                viewModel.activePicker = .location
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .foregroundStyle(foregroundColor)
                Text(hasSelectedLocation ? viewModel.locationSearch : "Where")
                    .font(.headline)
                    .foregroundStyle(hasSelectedLocation ? foregroundColor : Color(.systemGray))
//                Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: Capsule())
//            .background(Capsule()
//                .fill(Color(.systemGroupedBackground)))
        }
        .disabled(viewModel.activePicker == .date)
        .opacity(viewModel.activePicker == .date ? 0.4 : 1)
    }
}

#Preview {
    LocationSearchButton(viewModel: SearchViewModel())
}
