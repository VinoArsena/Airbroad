import SwiftUI
import Charts

struct ResultView: View {
    @Environment(CalendarViewModel.self) var calViewModel
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
            }
            .navigationTitle(formattedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
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
        DateFormatter.sgFullTitle.string(from: calViewModel.selectedDate)
    }
    
    // date picker
    private var datePicker: some View {
        HStack(spacing: 8) {
            ForEach(calViewModel.next3Days, id: \.self) { date in
                DateChip(
                    date: date,
                    isSelected: Calendar.singapore.isDate(date, inSameDayAs: calViewModel.selectedDate)
                ) {
                    withAnimation(.snappy) { calViewModel.select(date: date) }
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
            
            if let currentIndex = points.indices.contains(calViewModel.actualHour24) ? calViewModel.actualHour24 : nil,
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
                Text(viewModel.dailySummaryText)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        }
    }
    
    private var aboutAQICard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About \(viewModel.selectedPollutant.tabTitle)")
                .font(.title3.weight(.bold))
                .padding(.leading, 10)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.aboutBodyText)
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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ResultView()
        .environment(CalendarViewModel())
}
