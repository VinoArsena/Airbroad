
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
                    Image(level.maskImage)
                        .resizable()
                        .frame(maxWidth: 70, maxHeight: 70)
                        .padding(.leading, 10)
                        .padding(.trailing, 15)
                    
                    VStack(alignment: .leading, spacing: 10) {
                            Text(level.headline)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(level.recommendation)
                                .font(.caption)
//                                .foregroundStyle(Color(.systemGray))
                        if let better = nextBetterTime {
                            Text("Better condition expected around \(better).")
                                .font(.caption2)
//                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxHeight: 125)
                    .padding(.trailing, 10)
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
        .background(Color(.clear))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func pollutantColumn(label: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(Color(.systemGray))
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
    }
}
