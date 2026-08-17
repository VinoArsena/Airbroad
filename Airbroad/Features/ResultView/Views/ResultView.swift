import SwiftUI
import Charts

struct ResultView: View {
    @Bindable var viewModel = ResultViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    datePicker
                    pollutantPicker
                    aqiCard
                    dailySummaryCard
                    aboutAQICard
                }
                .padding(.horizontal)
//                .padding(.bottom, 15)
            }
            .navigationTitle(formattedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
//                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.days.isEmpty {
                    ProgressView()
                }
            }
            .alert("Something went wrong", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .navigationBarBackButtonHidden(true)
        }
    }
    
    
    private var formattedTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }
    
    // date picker
    private var datePicker: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.availableDates, id: \.self) { date in
                DateChip(
                    date: date,
                    isSelected: Calendar.singapore.isDate(date, inSameDayAs: viewModel.selectedDate)
                ) {
                    withAnimation(.snappy) { viewModel.select(date: date) }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
    }
    
    //segmented control
    private var pollutantPicker: some View {
        Picker("Pollutant", selection: $viewModel.selectedPollutant) {
            ForEach(PollutantType.allCases) { pollutant in
                Text(pollutant.tabTitle).tag(pollutant)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var aqiCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(currentValueText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                
                Spacer()
                
                if let category = viewModel.currentCategory {
                    Text(category.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            
            hourlyChart
                .frame(height: 200)
        }
        .padding()
        .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
    }
    
    private var currentValueText: String {
        guard let value = viewModel.selectedStats?.current else { return "—" }
        return String(format: "%.0f", value)
    }
    
    private var hourlyChart: some View {
        let points = Array(viewModel.chartValues.enumerated())
        
        return Chart {
            ForEach(points, id: \.offset) { hour, value in
                LineMark(
                    x: .value("Hour", hour),
                    y: .value("Value", value)
                )
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Hour", hour),
                    y: .value("Value", value)
                )
                .interpolationMethod(.catmullRom)
                .opacity(0.15)
            }
            
            if let currentIndex = points.indices.contains(viewModel.selectedHourIndex) ? viewModel.selectedHourIndex : nil,
               let currentValue = viewModel.chartValues[safe: currentIndex] {
                PointMark(
                    x: .value("Hour", currentIndex),
                    y: .value("Value", currentValue)
                )
                .symbolSize(80)
                .foregroundStyle(.primary)
            }
        }
        .foregroundStyle(
            .linearGradient(
                colors: [.green, .yellow, .orange, .red, .purple],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .chartXScale(domain: 0...23)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(String(format: "%02d", hour))
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
    }
    
    
    private var dailySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Summary")
                .font(.title3.weight(.bold))
                .padding(.leading, 10)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(dailySummaryText)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        }
    }
    
    private var dailySummaryText: String {
        guard let stats = viewModel.selectedStats, let category = viewModel.currentCategory else {
            return "Current \(viewModel.selectedPollutant.tabTitle) is unavailable right now."
        }
        
        let comparisonWord = stats.percentVsAverage >= 0 ? "higher" : "lower"
        let percentText = String(format: "%.0f", abs(stats.percentVsAverage))
        let lowestHourText = String(format: "%02d:00", stats.lowestUpcomingHour)
        
        func formatted(_ value: Double) -> String {
            let unit = viewModel.selectedPollutant.unit
            let number = viewModel.selectedPollutant == .aqi
            ? String(Int(value.rounded()))
            : String(format: "%.1f", value)
            return unit.isEmpty ? number : "\(number) \(unit)"
        }
        
        // ini copywritingnya bnerin ya ntar
        switch viewModel.selectedPollutant {
        case .aqi:
            let advice = category.recommendsStayingIndoors
            ? "not to go out or do outdoor activity"
            : "it's a good time for outdoor activity"
            return """
            Current AQI is \(formatted(stats.current)), you are suggested \(advice).
            Lower AQI expected to be around \(lowestHourText).
            Today's AQI range is from \(formatted(stats.min)) to \(formatted(stats.max)), it will be \(percentText)% \(comparisonWord) than daily average.
            """
            
        case .pm25:
            let advice = category.recommendsStayingIndoors
            ? "sensitive groups should limit prolonged outdoor exertion"
            : "fine particle levels are within a comfortable range"
            return """
            Current PM2.5 is \(formatted(stats.current)), \(advice).
            Cleanest air is expected around \(lowestHourText).
            Today's PM2.5 range is \(formatted(stats.min))–\(formatted(stats.max)), running \(percentText)% \(comparisonWord) than the daily average.
            """
            
        case .pm10:
            let advice = category.recommendsStayingIndoors
            ? "consider keeping windows closed if you're sensitive to dust and pollen"
            : "coarse particle levels look manageable today"
            return """
            Current PM10 is \(formatted(stats.current)), \(advice).
            Levels are expected to ease around \(lowestHourText).
            Today's PM10 range is \(formatted(stats.min))–\(formatted(stats.max)), which is \(percentText)% \(comparisonWord) than the daily average.
            """
            
        case .o3:
            let advice = category.recommendsStayingIndoors
            ? "ground-level ozone is elevated, so heavy outdoor exercise is best postponed"
            : "ozone levels are staying comfortably low"
            return """
            Current O3 is \(formatted(stats.current)), \(advice).
            Ozone is expected to be lowest around \(lowestHourText).
            Today's O3 range is \(formatted(stats.min))–\(formatted(stats.max)), tracking \(percentText)% \(comparisonWord) than the daily average.
            """
        }
    }
    
    
    private var aboutAQICard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About \(viewModel.selectedPollutant.tabTitle)")
                .font(.title3.weight(.bold))
                .padding(.leading, 10)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(aboutBodyText)
                Text("Data source: Open-Meteo Air Quality API.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
            
            Text("Forecast data is provided by Open-Meteo and may not always be fully accurate.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
        }
        
    }
    
    private var aboutBodyText: String {
        switch viewModel.selectedPollutant {
        case .aqi:
            return "The Air Quality Index (AQI) is a standardized metric for evaluating air quality that quantifies various pollutants (PM2.5, PM10, O3, etc.) into a single indicator value. Higher values indicate more immediate and severe impacts on respiratory and cardiovascular health, often manifesting within hours or days."
        case .pm25:
            return "PM2.5 consists of fine particulate matter ≤2.5 micrometers. It is highly dangerous because it can penetrate the lung barrier and enter directly into the bloodstream, triggering systemic oxidative stress and acute cardiovascular diseases, including heart failure. Its main sources are combustion residues (such as vehicle emissions and wildfires)."
        case .pm10:
            return "PM10 (inhalable particles ≤10 micrometers) is classified as coarse particulate matter, which includes road dust, pollen, and construction debris. PM10 is typically trapped in the upper respiratory tract, making it a primary cause of acute eye, nose, and throat irritation, and a major trigger for emergency hospital visits among asthma sufferers."
        case .o3:
            return "Ground-level (tropospheric) ozone is a secondary pollutant, unlike the natural stratospheric ozone that protects the earth. It is formed through chemical reactions between nitrogen oxides (NOx) from vehicles/industries and volatile organic compounds (VOCs) in the presence of sunlight. O3 is highly irritating; it inflames the airways, temporarily reduces lung function, and can trigger asthma attacks."
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ResultView()
}
