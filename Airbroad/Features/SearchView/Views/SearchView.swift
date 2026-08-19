
import SwiftUI
import CoreLocation

struct SearchView: View {
    @Environment(CalendarViewModel.self) var calViewModel
    @State var viewModel = SearchViewModel()
    @State var resViewModel = ResultViewModel()
    @State private var showDetailedPollutantSheet = false
    @State private var keyboard = KeyboardObserver()
    
    @FocusState private var textFieldClicked: Bool
    
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .ignoresSafeArea()
            
            ScrollView {
                if !viewModel.showSearchBar {
                    VStack {
                        //                    ShowLocationView(viewModel: viewModel)
                        //                        .padding(.top, 40)
                        
                        if !resViewModel.isLoading {
                            if let current = resViewModel.currentHourData,
                               let level = resViewModel.currentRiskLevel {
                                GuideCardView(
                                    srcViewModel: viewModel,
                                    resViewModel: resViewModel,
                                    current: current,
                                    level: level
                                )
                                .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 16))
                                .padding(.top, 20)
                                .padding(.bottom, 20)
                                
                                QualityPlotView(srcViewModel: viewModel, resViewModel: resViewModel)
                                    .padding(.bottom, 20)
                                
                                PollutantDetailView(viewModel: resViewModel)
                                
                                PollutantSummaryView(viewModel: resViewModel)
                            }
                        } else {
                            
                            VStack (alignment: .center) {
                                ProgressView()
                                Text("Fetching Location Data")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .padding(.top, 350)
                        }
                        
                    }
                    .padding()
                }
                else {
                    if viewModel.locationSearch != "" {
                        VStack(spacing: 0) {
                            ForEach(viewModel.locationSearchResults.prefix(4), id: \.self) { result in
                                LocationSuggestionView(
                                    viewModel: viewModel,
                                    textFieldClicked: $textFieldClicked,
                                    result: result
                                )
                                .padding(.horizontal, 30)
                                .padding(.bottom, 10)
                            }
                            
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
                .padding(.bottom, keyboard.height - 60)
                .animation(.easeOut(duration: 0.25), value: keyboard.height)
        }
        .scrollDismissesKeyboard(.interactively)
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
        .onAppear {
            resViewModel.calViewModel = calViewModel
        }
        .onChange(of: viewModel.pickedDate) { _, newDate in
            calViewModel.select(date: newDate)
        }
        .overlay {
            if viewModel.showCalendar {
                ZStack {
                    Color(.black)
                        .opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        WeekDayStrip(viewModel: viewModel)
                            .padding(.bottom, 85)
                            .padding()
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        
        .onTapGesture {
            guard viewModel.showSearchBar || viewModel.showCalendar else { return }
            withAnimation {
                viewModel.showSearchBar = false
                viewModel.showCalendar = false
                viewModel.activePicker = .none
            }
        }
    }
    
    private var bottomBar: some View {
        HStack {
            if (!viewModel.showSearchBar) {
                HStack {
                    Button(action: {
                        withAnimation(.easeIn) {
                            viewModel.showCalendar = true
                        }
                    }) {
                        Image(systemName: "calendar")
                            .font(.headline)
                            .padding()
                            .glassEffect()
                    }
                    .contentShape(Circle())
                    
                    Spacer()
                    
                    Text(displayLabel)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .glassEffect()
                    
                    Spacer()
                }
                
                .padding(.bottom, 20)
            } else {
                HStack {
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
                        
                        if !viewModel.locationSearch.isEmpty {
                            Button(action: {
                                viewModel.locationSearch = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(4)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .font(.body)
                    .padding(15)
                    .glassEffect()
                    .padding(5)
                }
                
            }
            Button(action: {
                if viewModel.showSearchBar {
                    withAnimation(.easeOut) {
                        textFieldClicked = false
                        viewModel.showSearchBar = false
                    }
                } else {
                    withAnimation(.easeIn) {
                        viewModel.showSearchBar = true
                    }
                }
                
            }) {
                Image(systemName: viewModel.showSearchBar ? "xmark" : "magnifyingglass")
                    .font(.headline)
                    .padding()
                    .glassEffect()
            }
            .contentShape(Circle())
            .padding(.bottom, viewModel.showSearchBar ? 0 : 20)
            
            
        }
        //        .padding(.bottom, viewModel.showSearchBar ? 200 : 0)
        .buttonStyle(.plain)
        .padding()
        .font(.title)
        .padding()
    }
    
    private var displayLabel: String {
        Calendar.singapore.isDateInToday(viewModel.pickedDate)
        ? "Today"
        : viewModel.pickedDate.formatted(Date.FormatStyle(timeZone: .singapore).weekday(.abbreviated).day().month(.abbreviated))
    }
}

#Preview {
    SearchView()
        .environment(CalendarViewModel())
}
