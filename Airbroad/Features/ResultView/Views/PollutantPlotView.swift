import SwiftUI

struct PollutantPlotView: View {
    @Bindable var viewModel: ResultViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text("\(viewModel.selectedPollutant)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Moderate")
                    .font(.body)
                    .foregroundStyle(Color(.systemGray))
            }
            
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 200))
                .background(Color(.secondarySystemGroupedBackground))
                .padding(.top, 5)
        }
        .padding(20)
        .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    PollutantPlotView(viewModel: ResultViewModel())
}
