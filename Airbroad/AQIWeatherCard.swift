import SwiftUI

struct AQIWeatherCard: View {
    let aqi: Int          // e.g. 61
    let riskLabel: String // e.g. "Slight Risk"
    let pm25: Double
    let ozone: Double
    
    // Scale range mapping (0 to 300 AQI)
    private var progress: Double {
        min(max(Double(aqi) / 300.0, 0.0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "aqi.medium")
                    .font(.caption.bold())
                Text("AIR QUALITY & RISK")
                    .font(.caption.bold())
            }
            .foregroundStyle(.secondary)

            // Value & Risk Status
            VStack(alignment: .leading, spacing: 2) {
                Text("\(aqi)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text(riskLabel)
                    .font(.subheadline.weight(.semibold))
            }

            // Apple Weather-style Gradient AQI Scale
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Gradient Track
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .orange, .red, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 5)

                    // Current Value Indicator Dot
                    Circle()
                        .fill(.white)
                        .frame(width: 9, height: 9)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: (geometry.size.width - 9) * progress)
                }
            }
            .frame(height: 10)

            Divider()
                .opacity(0.3)

            // Metric Details Row
            HStack {
                metricCell(title: "PM2.5", value: String(format: "%.1f µg/m³", pm25))
                Spacer()
                metricCell(title: "Ozone", value: String(format: "%.0f ppb", ozone))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .environment(\.colorScheme, .dark) // Matches native weather dark background context
    }

    private func metricCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.medium))
        }
    }
}

#Preview {
    ZStack {
        // Simulated Weather App Background
        LinearGradient(
            colors: [Color.blue.opacity(0.8), Color.indigo],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        AQIWeatherCard(
            aqi: 61,
            riskLabel: "Slight Risk",
            pm25: 14.0,
            ozone: 48.0
        )
        .padding()
    }
}
