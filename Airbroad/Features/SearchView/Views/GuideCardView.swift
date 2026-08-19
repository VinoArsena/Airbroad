
import SwiftUI

struct GuideCardView: View {
    let srcViewModel: SearchViewModel
    let resViewModel: ResultViewModel
    let current: RiskDisplayItem
    let level: RiskLevel
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text((hasSelectedLocation && srcViewModel.locationSearch != "") ? srcViewModel.locationSearch : "Singapore")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            HStack(alignment: .center, spacing: 16) {
                Image(level.maskImage)
                    .resizable()
                    .frame(maxWidth: 70, maxHeight: 70)
                    .padding(.horizontal, 10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(level.headline)
                        .font(.subheadline)
                    
                    Text(level.recommendation)
                        .font(.title3)
                        .fontWeight(.bold)
                    //                                .foregroundStyle(Color(.systemGray))
                    
                }
                .multilineTextAlignment(.leading)
                //                    .frame(maxHeight: 135)
                .padding(.trailing, 10)
            }
            .padding(.vertical, 5)
            .padding(.horizontal)
            
            if let better = resViewModel.nextBetterTime {
                Divider()
                
                Text("Better condition expected around \(better).")
                    .font(.caption2)
                    .padding(.top, 10)
                //                                .foregroundStyle(Color(.systemGray))
            }
            
        }
        //        .background(Color(.clear))
        .padding()
        .contentShape(RoundedRectangle(cornerRadius: 16))
        
        var hasSelectedLocation: Bool {
            srcViewModel.selectedDestination != nil
        }
    }
    
    @ViewBuilder
    private func pollutantColumn(label: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(Color(.systemGray))
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
    }
}
