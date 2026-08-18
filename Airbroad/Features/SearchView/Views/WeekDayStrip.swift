import SwiftUI

struct WeekDayStrip: View {
    @Environment(CalendarViewModel.self) var calViewModel
    @Bindable var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.pickedDate.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            
            Divider()
            
            HStack(spacing: 30) {
                ForEach(calViewModel.next3Days, id: \.self) { (day: Date) in
                    let isSelected = Calendar.singapore.isDate(day, inSameDayAs: viewModel.pickedDate)
                    Button {
                        withAnimation {
                            viewModel.pickedDate = day
                            viewModel.activePicker = .none   // FIX: auto-close
                            viewModel.showCalendar = false
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(day.formatted(Date.FormatStyle(timeZone: .singapore).weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(Color(.systemGray))
                            Text(day.formatted(Date.FormatStyle(timeZone: .singapore).day()))
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
        .environment(CalendarViewModel())
}
