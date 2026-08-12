import SwiftUI
import Charts
import Foundation
import Combine


// MARK: - Data Model

struct HourlyAQIPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

// MARK: - Refactored Weather Line Chart View

struct HourlyAQIChartView: View {
    let points: [HourlyAQIPoint]
    
    // MARK: - Computed Bounds
    
    private var highPoint: HourlyAQIPoint? {
        points.max(by: { $0.value < $1.value })
    }
    
    private var lowPoint: HourlyAQIPoint? {
        points.min(by: { $0.value < $1.value })
    }
    
    private var yMin: Double {
        let minVal = points.map(\.value).min() ?? 0
        return max(0, minVal - 15)
    }
    
    private var yMax: Double {
        let maxVal = points.map(\.value).max() ?? 100
        return maxVal + 15
    }

    // MARK: - Extracted Gradients

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.orange.opacity(0.5),
                Color.yellow.opacity(0.25),
                Color.teal.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .yellow],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartView
        }
        .padding(16)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Chart Core Sub-Expression

    private var chartView: some View {
        Chart {
            areaSeries
            lineSeries
            highLowMarkers
        }
        .chartYScale(domain: yMin...yMax)
        .chartXAxis { xAxisContent }
        .chartYAxis { yAxisContent }
        .frame(height: 180)
    }

    // MARK: - Chart Content Sub-Expressions

    @ChartContentBuilder
    private var areaSeries: some ChartContent {
        ForEach(points) { point in
            AreaMark(
                x: .value("Time", point.time),
                yStart: .value("Baseline", yMin),
                yEnd: .value("AQI", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(areaGradient)
        }
    }

    @ChartContentBuilder
    private var lineSeries: some ChartContent {
        ForEach(points) { point in
            LineMark(
                x: .value("Time", point.time),
                y: .value("AQI", point.value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            .foregroundStyle(lineGradient)
        }
    }

    @ChartContentBuilder
    private var highLowMarkers: some ChartContent {
        if let low = lowPoint {
            PointMark(
                x: .value("Time", low.time),
                y: .value("AQI", low.value)
            )
            .symbol {
                ChartMarkerNode(label: "L")
            }
        }

        if let high = highPoint {
            PointMark(
                x: .value("Time", high.time),
                y: .value("AQI", high.value)
            )
            .symbol {
                ChartMarkerNode(label: "H")
            }
        }
    }

    // MARK: - Axis Sub-Expressions

    private var xAxisContent: some AxisContent {
        AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                .foregroundStyle(Color.white.opacity(0.15))
            AxisValueLabel(format: Date.FormatStyle.dateTime.hour(.defaultDigits(amPM: .wide)))
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
    }

    private var yAxisContent: some AxisContent {
        AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                .foregroundStyle(Color.white.opacity(0.15))
            AxisValueLabel()
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Custom Marker Node

private struct ChartMarkerNode: View {
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.white)
            
            Circle()
                .strokeBorder(Color.black, lineWidth: 2)
                .background(Circle().fill(Color.white))
                .frame(width: 8, height: 8)
        }
        .offset(y: -10)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    let sampleValues: [Double] = [
        82, 80, 78, 77, 76, 75, 78, 82, 87, 92, 95, 97,
        98, 96, 93, 89, 87, 83, 81, 80, 79, 78, 77, 76
    ]
    
    let mockData = sampleValues.enumerated().map { index, val in
        HourlyAQIPoint(
            time: calendar.date(byAdding: .hour, value: index, to: today)!,
            value: val
        )
    }
    
    ZStack {
        Color.black.ignoresSafeArea()
        HourlyAQIChartView(points: mockData)
            .padding()
    }
}
