import SwiftUI

struct DateChip: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekdayLabel)
                    .font(.callout)
                    .foregroundStyle(Color(.systemGray))
                
                Text(dayLabel)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .fontWeight(isSelected ? .bold : .medium)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(.blue) : Color(.clear))
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var weekdayLabel: String {
        String(DateFormatter.sgWeekday.string(from: date).prefix(1))
    }
    
    private var dayLabel: String {
        DateFormatter.sgDay.string(from: date)
    }
}
