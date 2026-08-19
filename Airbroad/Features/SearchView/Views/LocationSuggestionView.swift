
import SwiftUI
import MapKit

struct LocationSuggestionView: View {
    @Bindable var viewModel: SearchViewModel
//    @Binding var currentPresentationDetents: PresentationDetent
    @FocusState.Binding var textFieldClicked: Bool
    @State private var distanceText: String = ""
    
    var result: MKLocalSearchCompletion
    
    var body: some View {
        Button {
            selectDestination()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(Color(.white))
                                .font(.system(size: 14))
                        )
                        .padding(.trailing, 20)
                    
                    VStack(alignment: .leading) {
                        Text(result.title)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(result.subtitle)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(Color(.systemGray2))
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                }
    
//                Divider()
//                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 40)
            .contentShape(Rectangle())
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
    
    private func selectDestination() {
        textFieldClicked = false
        
        Task {
            await viewModel.selectCompletion(result)
            viewModel.showSearchBar = false
        }
    }
}
