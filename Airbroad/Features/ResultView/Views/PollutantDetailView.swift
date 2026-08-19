
import SwiftUI
import Charts

struct PollutantDetailView: View {
    @Environment(CalendarViewModel.self) var calViewModel
    @Bindable var viewModel: ResultViewModel
    @State private var selectedHour: Int?
 
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.title)
                .fontWeight(.bold)
            
            pollutantPicker
            aqiCard
        }
        .padding()
        .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        .overlay {
            if viewModel.isLoading && viewModel.days.isEmpty {
                ProgressView()
            }
        }
    }
    
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
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let category = viewModel.currentCategory {
                    Text(category.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
//                        .foregroundStyle(viewModel.textColor)
                }
            }
            .opacity(selectedHour == nil ? 1 : 0)
            
            hourlyChart
                .frame(height: 200)
        }
        .padding(.horizontal)
    }
    
    private var currentValueText: String {
        guard let value = viewModel.selectedStats?.current else { return "—" }
        return String(format: "%.0f", value)
    }
    
    private var displayedHour: Int {
        let raw = selectedHour ?? calViewModel.actualHour24
        return min(max(raw, 0), max(viewModel.chartValues.count - 1, 0))
    }
    
    private var hourlyChart: some View {
        let points = Array(viewModel.chartValues.enumerated())

            return Chart {
                ForEach(points, id: \.offset) { hour, value in
                    LineMark(x: .value("Hour", hour), y: .value("Value", value))
                        .interpolationMethod(.catmullRom)

                    AreaMark(x: .value("Hour", hour), y: .value("Value", value))
                        .interpolationMethod(.catmullRom)
                        .opacity(0.15)
                }

                if let currentValue = viewModel.chartValues[safe: displayedHour] {
                    RuleMark(x: .value("Hour", displayedHour))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    if selectedHour != nil {
                            PointMark(x: .value("Hour", displayedHour), y: .value("Value", currentValue))
                                .symbolSize(80)
                                .foregroundStyle(Color.black)
                        } else {
                            PointMark(x: .value("Hour", displayedHour), y: .value("Value", currentValue))
                                .symbolSize(80)
                                // no foregroundStyle override — inherits the chart's gradient, matching the line
                        }
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
            .chartXSelection(value: $selectedHour)
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
            .chartOverlay { proxy in
                GeometryReader { geo in
                    if selectedHour != nil {
                        if let plotFrame = proxy.plotFrame,
                           let value = viewModel.chartValues[safe: displayedHour] {
                            let plotRect = geo[plotFrame]
                            if let xPos = proxy.position(forX: displayedHour) {
                                let bubbleWidth: CGFloat = 70
                                let rawX = plotRect.origin.x + xPos
                                let clampedX = min(
                                    max(rawX, plotRect.minX + bubbleWidth / 2),
                                    plotRect.maxX - bubbleWidth / 2
                                )
                                
                                
                                VStack(spacing: 2) {
                                    Text(String(format: "%02d:00", displayedHour))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.0f", value))
                                        .font(.headline)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            
                                .frame(width: bubbleWidth)
                                .position(x: clampedX, y: plotRect.minY - 35)
                            }
                        }
                    }
                    
                }
            }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
