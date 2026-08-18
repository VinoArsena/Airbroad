import SwiftUI

struct DateTimePickerButton: View {
    @Bindable var viewModel: SearchViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var displayLabel: String {
        Calendar.singapore.isDateInToday(viewModel.pickedDate)
        ? "Today"
        : viewModel.pickedDate.formatted(Date.FormatStyle(timeZone: .singapore).weekday(.abbreviated).day().month(.abbreviated))
    }
    
    private var isShowingPicker: Binding<Bool> {
        Binding(
            get: { viewModel.activePicker == .date },
            set: { viewModel.activePicker = $0 ? .date : .none }
        )
    }
    
    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        Button {
            if (viewModel.showCalendar == true) {
                viewModel.showCalendar = false
                viewModel.activePicker = .none
            } else {
                viewModel.showCalendar = true
                viewModel.activePicker = .date
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(displayLabel).font(.headline)
                    .foregroundStyle(foregroundColor)
                //                Image(systemName: viewModel.activePicker == .date ? "chevron.up" : "chevron.down")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .glassEffect(.regular.tint(Color(.systemGroupedBackground)), in: Capsule())
        }
        .disabled(viewModel.activePicker == .location)
        .opacity(viewModel.activePicker == .location ? 0.4 : 1)
        //        .popover(isPresented: isShowingPicker, arrowEdge: .top) {
        //            WeekDayStrip(viewModel: viewModel)
        //                .presentationCompactAdaptation(.popover)
        //        }
    }
}

#Preview {
    DateTimePickerButton(viewModel: SearchViewModel())
}
