import SwiftUI

struct WeekDayStrip: View {
    @Bindable var viewModel: SearchViewModel

    private var next4Days: [Date] {
        (0...3).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: viewModel.minSelectableDate)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
//            HStack {
                Text(viewModel.pickedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
//                Spacer()
//                Button {
//                    viewModel.activePicker = .none
//                } label: {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundStyle(Color(.systemGray3))
//                        .font(.title2)
//                }
//            }
            
            Divider()

            HStack(spacing: 30) {
                ForEach(next4Days, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: viewModel.pickedDate)
                    Button {
                        withAnimation {
                            viewModel.pickedDate = day
                            viewModel.activePicker = .none   // FIX: auto-close
                            viewModel.showCalendar = false
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                            Text(day.formatted(.dateTime.day()))
                                .font(.headline)
                                .foregroundStyle(isSelected ? .white : .primary)
                                .frame(width: 32, height: 32)
                                .background(isSelected ? Color.blue : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    WeekDayStrip(viewModel: SearchViewModel())
}
