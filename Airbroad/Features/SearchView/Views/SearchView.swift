import SwiftUI
import MapKit

struct SearchView: View {
    @Environment(CalendarViewModel.self) var calViewModel
    @Bindable var viewModel = SearchViewModel()
    @Bindable var resViewModel = ResultViewModel()
    @State private var showDetailedPollutantSheet = false
    
    var body: some View {
        ZStack (alignment: .top){
            
            Image("background")
                .frame(width: 402, height: 874)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard viewModel.showSearchBar || viewModel.showCalendar else { return }
                    withAnimation {
                        viewModel.showSearchBar = false
                        viewModel.showCalendar = false
                        viewModel.activePicker = .none
                    }
                }
            
            Color(.systemGray)
                .opacity(resViewModel.pollutantOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeInOut)
            
            ParticleOverlayView(resViewModel: resViewModel)
            
            VStack {
                Spacer()
                bottomTimePanel
            }
            .padding(20)
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            topCluster
                .padding(20)
                .padding(.top, 30)
        }
        .safeAreaInset(edge: .bottom) {
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear{
            resViewModel.calViewModel = calViewModel
        }
        .sheet(isPresented: $showDetailedPollutantSheet) {
            ResultView(viewModel: resViewModel)
        }
//        .onChange(of: calViewModel.actualHour24) { _, newHour in
//            calViewModel.actualHour24 = newHour
//        }
        .task(id: viewModel.pickedDate) {
            calViewModel.select(date: viewModel.pickedDate)
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
        .navigationBarBackButtonHidden(true)
        
    }
    
    private var topCluster: some View {
        VStack {
            HStack {
                LocationSearchButton(viewModel: viewModel)
                DateTimePickerButton(viewModel: viewModel)
            }
            .buttonStyle(.plain)
            
            if viewModel.showSearchBar {
                SearchBarView(viewModel: viewModel)
                    .padding(.top, 100)
                    .contentShape(Rectangle())
                    .onTapGesture {}
            }
            
            if viewModel.showCalendar {
                WeekDayStrip(viewModel: viewModel)
                .padding(.top, 10)
                .contentShape(Rectangle())
                .onTapGesture {}
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
                        .glassEffect(.regular.tint(Color(.clear)), in: .rect(cornerRadius: 16))
                        .padding(.top, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var bottomTimePanel: some View {
        @Bindable var calViewModel = calViewModel
        
        return VStack (alignment: .leading) {
            let date = Calendar.singapore.isDateInToday(viewModel.pickedDate)
            ? "Today"
            : viewModel.pickedDate.formatted(Date.FormatStyle(timeZone: .singapore).weekday(.abbreviated).day().month(.abbreviated))
            
            HStack (alignment: .top){
                VStack (alignment: .leading) {
                    Text(viewModel.selectedDestination?.title ?? "Singapore")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(date)
                        .font(.body)
                        .foregroundStyle(Color(.systemGray))
                }
                
                Spacer()
                
                VStack (alignment: .trailing, spacing: 6){
                    Text(  calViewModel.currentTime12Hour).font(.title3)
                        .fontWeight(.bold)
                    SunMoonToggle(isPM: $calViewModel.isPM)
                }
                
            }
            
            Slider(
                value: $calViewModel.sliderHour12,
                in: 0...11,
                step: 1,
                label: { Text("Time") },
                tick: { value in
                    SliderTick(value) {
                        let displayed = Int(value) == 0 ? 12 : Int(value)
                        let realHour24 = Calendar.singapore.component(.hour, from: Date())
                        let realHour12 = realHour24 % 12
                        let realIsPM = realHour24 >= 12
                        if Int(value) == realHour12 && calViewModel.isPM == realIsPM {
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
}

#Preview {
    SearchView()
        .environment(CalendarViewModel())
}
