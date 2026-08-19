import SwiftUI
import Charts

struct PollutantSummaryView: View {
    @Environment(CalendarViewModel.self) var calViewModel
    @Bindable var viewModel: ResultViewModel
    @State private var selectedHour: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            dailySummaryCard
                .padding(.top, 20)
            aboutPollutantCard
        }
    }
    
    private var dailySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Summary")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Divider()
                
                Text(viewModel.dailySummaryText)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.clear.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        }
    }
    
    private var aboutPollutantCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack (alignment: .leading){
                Text("About \(viewModel.selectedPollutant.tabTitle)")
                    .font(.title3.weight(.bold))
                    .padding(.top, 5)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.aboutBodyText)
                    Text("Data source: Open-Meteo Air Quality API.")
                        .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.clear.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        }
    }
}


private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
