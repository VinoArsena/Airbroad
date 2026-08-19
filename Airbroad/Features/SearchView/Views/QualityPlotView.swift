import SwiftUI
import Charts

struct QualityPlotView: View {
    @Bindable var srcViewModel: SearchViewModel
    @Bindable var resViewModel: ResultViewModel
    @Environment(CalendarViewModel.self) var calViewModel
    
    var displayLabel: String
    @State private var selectedHour: Int?
    
    
    var body: some View {
        if let activeItem {
            VStack (alignment: .leading) {
                if displayLabel == "Today" {
                    Text("Today's Overview")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                        .opacity(selectedHour == nil ? 1 : 0)
                } else {
                    Text("\(displayLabel) Overview")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                        .opacity(selectedHour == nil ? 1 : 0)
                }
                
                
                Divider()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 20) {
                            ForEach(Array(results.enumerated()), id: \.offset) { hour, item in
                                let isCurrentHour = Calendar.singapore.isDateInToday(calViewModel.selectedDate) && hour == calViewModel.actualHour24
                                let isPast = Calendar.singapore.isDateInToday(calViewModel.selectedDate) && hour < calViewModel.actualHour24
                                let isSelected = selectedHour == hour
                                
                                
                                VStack(spacing: 10) {
                                    Text(isCurrentHour ? "Now" : String(format: "%02d", hour))
                                        .font(.caption.weight(isCurrentHour || isSelected ? .bold : .medium))
                                        .foregroundStyle(isCurrentHour ? .primary : .secondary)
                                    
                                    Image(item.riskLevel.maskImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                    
                                    Text(item.riskLevel.label)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(item.riskLevel.color)
                                    
                                    Circle()
                                        .fill(item.riskLevel.color)
                                        .frame(width: 6, height: 6)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
//                                .frame(width: 58)
                                .opacity(isPast && !isSelected ? 0.45 : 1.0)
                                .id(hour)
                            }
                        }
                        .padding(.horizontal, 4)
                        .onAppear {
                            // Auto-scroll to current hour on load
                            if Calendar.singapore.isDateInToday(calViewModel.selectedDate) {
                                proxy.scrollTo(calViewModel.actualHour24, anchor: .center)
                            }
                        }
                    }
                }
            }
            //                Chart {
            //                    ForEach(Array(resViewModel.results.enumerated()), id: \.offset) { hour, item in
            //                        LineMark(
            //                            x: .value("Hour", hour),
            //                            y: .value("Risk", item.riskLevel.rawValue)
            //                        )
            //                        .interpolationMethod(.stepStart)
            //                        .lineStyle(StrokeStyle(lineWidth: 2.5))
            //                        .foregroundStyle(.primary)
            //
            //                        AreaMark(
            //                            x: .value("Hour", hour),
            //                            y: .value("Risk", item.riskLevel.rawValue)
            //                        )
            //                        .interpolationMethod(.stepStart)
            //                        .foregroundStyle(
            //                            .linearGradient(
            //                                colors: [
            //                                    .red.opacity(0.45),
            //                                    .orange.opacity(0.3),
            //                                    .yellow.opacity(0.2),
            //                                    .green.opacity(0.08)
            //                                ],
            //                                startPoint: .top,
            //                                endPoint: .bottom
            //                            )
            //                        )
            //                    }
            //
            ////                    if Calendar.singapore.isDateInToday(calViewModel.selectedDate), calViewModel.actualHour24 > 0 {
            ////                        RectangleMark(
            ////                            xStart: .value("Start", 0),
            ////                            xEnd: .value("Past", calViewModel.actualHour24),
            ////                            yStart: .value("MinRisk", 0),
            ////                            yEnd: .value("MaxRisk", 3)
            ////                        )
            ////                        .foregroundStyle(.black.opacity(0.2))
            ////                    }
            ////
            //                    if let selectedHour {
            //                        RuleMark(x: .value("Hour", selectedHour))
            //                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            //                            .foregroundStyle(.secondary)
            //                            .annotation(position: .top, spacing: 10, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
            //                                VStack(alignment: .center, spacing: 3) {
            //                                    Text("(\(activeItem.time))")
            //                                        .font(.caption)
            //                                    HStack(alignment: .center, spacing: 4) {
            //                                        Image(activeItem.riskLevel.maskImage)
            //                                            .resizable()
            //                                            .frame(width: 20, height: 20)
            //                                        Text(activeItem.riskLevel.label)
            //                                            .font(.body)
            //                                            .fontWeight(.bold)
            //
            //
            //                                    }
            //                                }
            //                                .padding(.horizontal, 10)
            //                                .padding(.vertical, 6)
            //                            }
            //
            //                        PointMark(
            //                            x: .value("Hour", selectedHour),
            //                            y: .value("Risk", activeItem.riskLevel.rawValue)
            //                        )
            //                        .symbolSize(50)
            //                        .foregroundStyle(.black)
            //                    } else {
            //                        RuleMark(x: .value("Hour", activeHour))
            //                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            //                            .foregroundStyle(.secondary)
            //
            //                        PointMark(
            //                            x: .value("Hour", activeHour),
            //                            y: .value("Risk", activeItem.riskLevel.rawValue)
            //                        )
            //                        .symbolSize(90)
            //                        .foregroundStyle(activeItem.riskLevel.color)
            //                    }
            //
            //                }
            //                .chartXScale(domain: 0...23)
            //                .chartYScale(domain: 0...3)
            //                .chartXSelection(value: $selectedHour)
            //                .chartXAxis {
            //                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
            //                        AxisValueLabel {
            //                            if let hour = value.as(Int.self) {
            //                                Text(String(format: "%02d", hour))
            //                            }
            //                        }
            //                        AxisGridLine()
            //                    }
            //                }
            //                .chartYAxis {
            //                    AxisMarks(values: [0, 1, 2, 3]) { value in
            //                        AxisValueLabel {
            //                            if let raw = value.as(Int.self),
            //                               let level = RiskLevel(rawValue: raw) {
            //                                Text(level.label)
            //                                    .font(.caption2)
            //                                    .fontWeight(.bold)
            //                            }
            //                        }
            //                        AxisGridLine()
            //                    }
            //                }
            //                .frame(height: 200)
            //                .padding(.horizontal)
            
            
            .padding()
            .glassEffect(.clear.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
        }
        
    }
    
    private var results: [RiskDisplayItem] {
        resViewModel.results
    }
    
    private var activeHour: Int {
        guard !results.isEmpty else { return 0 }
        let rawHour = selectedHour ?? calViewModel.actualHour24
        return min(max(rawHour, 0), results.count - 1)
    }
    
    private var activeItem: RiskDisplayItem? {
        results[activeHour]
    }
    
}
