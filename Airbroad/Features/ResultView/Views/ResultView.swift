
import SwiftUI

struct ResultView: View {
    @Bindable var viewModel = ResultViewModel()
    @Bindable var searchViewModel = SearchViewModel()
    
    var body: some View {
        ScrollView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    //                HStack {
                    Text("\(viewModel.selectedDate.formatted(date: .complete, time: .omitted))")
                        .padding(.bottom, 10)
                        .fontWeight(.semibold)
                    //                }
                    
                    
                    HStack() {
                        ForEach(viewModel.weekDates, id: \.self) { date in
                            let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                            
                            Button (action: {viewModel.selectedDate = date}) {
                                VStack(spacing: 8) {
                                    Text(date, format: .dateTime.weekday(.narrow))
                                        .font(.callout)
                                        .foregroundStyle(Color(.systemGray))
                                    
                                    Text(date, format: .dateTime.day())
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(isSelected ? .white : .primary)
                                        .fontWeight(isSelected ? .semibold : .light)
                                        .background(
                                            Circle()
                                                .fill(isSelected ? Color(.blue) : Color(.clear))
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
                    .padding(.bottom, 15)
                    
                    Picker("", selection: $viewModel.selectedPollutant) {
                        ForEach(viewModel.pollutants, id: \.self) { pollutant in
                            Text(pollutant)
                        }
                        .font(.callout)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 15)
                    .padding(.horizontal, 15)
                    
                    PollutantPlotView(viewModel: viewModel)
                        .padding(.horizontal, 15)
                        .padding(.bottom, 15)
                    
                    DailySummaryView(viewModel: viewModel)
                        .padding(.horizontal, 15)
                        .padding(.bottom, 15)
                    
                    AboutPollutantView(viewModel: viewModel)
                        .padding(.horizontal, 15)
                    
                }
                
                
            }
            
        }
        
    }
}

#Preview {
    ResultView()
}
