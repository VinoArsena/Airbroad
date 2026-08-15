import SwiftUI
import MapKit

struct SearchView: View {
    @Bindable var viewModel = SearchViewModel()
    @Bindable var resViewModel = ResultViewModel()
    
    @State private var showDetailedPollutantSheet = false
    
    var body: some View {
        ZStack (alignment: .top){
            //            Color(.systemBackground)
            
            Image("background")
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    LocationSearchButton(viewModel: viewModel)
                    DateTimePickerButton(viewModel: viewModel)
                }
                .buttonStyle(.plain)
                
                if viewModel.showSearchBar {
                    SearchBarView(viewModel: viewModel)
                        .padding(.top, 10)
                }
                
                if viewModel.showCalendar {
                    WeekDayStrip(viewModel: viewModel)
                        .padding(.top, 10)
                }
                
                if !viewModel.showSearchBar && !viewModel.showCalendar && !resViewModel.isLoading {
                    if let current = resViewModel.currentHourData,
                       let level = resViewModel.currentRiskLevel {
                        Button(action: { showDetailedPollutantSheet = true }) {
                            RecommendationCardView(
                                isLoading: resViewModel.isLoading,
                                current: current,
                                level: level,
                                nextBetterTime: resViewModel.nextBetterTime
                            )
                            .padding(.top, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                VStack (alignment: .leading) {
                    let date = Calendar.current.isDateInToday(viewModel.pickedDate)
                    ? "Today"
                    : viewModel.pickedDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    
                    HStack (alignment: .top){
                        VStack (alignment: .leading) {
                            Text(viewModel.selectedDestination?.title ?? "Singapore")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(date)
                                .font(.body)
                                .foregroundStyle(Color(.systemGray))
                        }
                        
                        Spacer()
                        
                        VStack (alignment: .trailing, spacing: 6){
                            Text(  viewModel.currentTime12Hour).font(.title)
                                .fontWeight(.bold)
                            SunMoonToggle(isPM: $viewModel.isPM)
                        }
                        
                    }
                    
                    Slider(
                        value: $viewModel.sliderHour12,
                        in: 0...11,
                        step: 1,
                        label: { Text("Time") },
                        tick: { value in
                            SliderTick(value) {
                                let displayed = Int(value) == 0 ? 12 : Int(value)
                                let realHour24 = Calendar.current.component(.hour, from: Date())
                                let realHour12 = realHour24 % 12
                                let realIsPM = realHour24 >= 12
                                if Int(value) == realHour12 && viewModel.isPM == realIsPM {
                                    Text("Now").font(.caption2).fontWeight(.semibold)
                                } else {
                                    Text("\(displayed)").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        },
                        onEditingChanged: { editing in viewModel.isEditing = editing }
                    )
                }
                .padding(20)
                .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
                
                
            }
            .padding(20)
            .padding(.top, 30)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showDetailedPollutantSheet) {
            ResultView(viewModel: resViewModel)
        }
        .onChange(of: viewModel.actualHour24) { _, newHour in
            resViewModel.selectedHourIndex = newHour
        }
        .task(id: viewModel.pickedDate) {
            resViewModel.select(date: viewModel.pickedDate)
        }
        .task {
            await resViewModel.loadInitialLocation()
        }
        .task(id: viewModel.selectedDestination?.id) {
            guard let destination = viewModel.selectedDestination else { return }
            await resViewModel.loadForecast(
                lat: destination.coordinate.latitude,
                lon: destination.coordinate.longitude
            )
        }
        
    }
}

#Preview {
    SearchView()
}
