import SwiftUI

struct DailySummaryView: View {
    @Bindable var viewModel: ResultViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Daily Summary \(viewModel.selectedPollutant)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
            
            VStack(alignment: .leading) {
                Text("Current AQI is ..., you are suggested not to go out/do activity outdoor.")
                Text("Lower AQI expected to be around 17.00.")
                Text("Today’s AQI range is from 50 to 100, it will be ...% lower/higher than daily average.")
            }
            .padding(20)
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
           
        }
            
        
    }
}

#Preview {
    DailySummaryView(viewModel: ResultViewModel())
}
