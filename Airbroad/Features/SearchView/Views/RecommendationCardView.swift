
import SwiftUI

struct RecommendationCardView: View {
    let isLoading: Bool
    let current: RiskDisplayItem
    let level: RiskLevel
    let nextBetterTime: String?
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 0) {
            if isLoading {
                Text("Fetching AQI Data")
            } else {
                HStack(alignment: .center, spacing: 16) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray4))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text("Mask\nImage")
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color(.systemGray))
                        )
                        .padding(.trailing, 5)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(level.headline)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(level.recommendation)
                            .font(.caption)
                            .foregroundStyle(Color(.systemGray))
                        if let better = nextBetterTime {
                            Text("Better condition expected around \(better).")
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                }
                .padding()
                
                Divider()
                
                HStack(alignment: .center, spacing: 15) {
                    pollutantColumn(label: "AQI", value: "\(Int(current.point.aqi))")
                        .frame(maxWidth: .infinity)
                    pollutantColumn(label: "PM2.5", value: "\(Int(current.point.pm2_5)) µg/m³")
                        .frame(maxWidth: .infinity)
                    pollutantColumn(label: "PM10", value: "\(Int(current.point.pm10)) µg/m³")
                        .frame(maxWidth: .infinity)
                    pollutantColumn(label: "O3", value: "\(Int(current.point.ozone)) ppb")
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 10)
                }
                .padding(.vertical)
            
            }
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func pollutantColumn(label: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(Color(.systemGray))
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
    }
}
