import SwiftUI

struct DatePickerView: View {
    @StateObject private var viewModel: DatePickerViewModel
    let onSelectionChanged: (Date?, Date?) -> Void

    init(
        maxRangeSpanDays: Int = 7,
        onSelectionChanged: @escaping (Date?, Date?) -> Void = { _, _ in }
    ) {
        _viewModel = StateObject(wrappedValue: DatePickerViewModel(maxRangeSpanDays: maxRangeSpanDays))
        self.onSelectionChanged = onSelectionChanged
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                DatePickerCardView(
                    monthDate: viewModel.baseMonth,
                    viewModel: viewModel,
                    showsPreviousChevron: true,
                    showsNextChevron: false
                )
                DatePickerCardView(
                    monthDate: viewModel.nextMonth,
                    viewModel: viewModel,
                    showsPreviousChevron: false,
                    showsNextChevron: true
                )
            }
            summary
        }
        .padding()
        .onChange(of: viewModel.startDate) { _, _ in notify() }
        .onChange(of: viewModel.endDate) { _, _ in notify() }
    }

    @ViewBuilder
    private var summary: some View {
        if let start = viewModel.startDate {
            HStack {
                Text(start, format: .dateTime.month().day())
                if let end = viewModel.endDate {
                    Text("–")
                    Text(end, format: .dateTime.month().day())
                } else {
                    Text("Select end date")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reset") { viewModel.reset() }
                    .font(.footnote)
            }
            .font(.subheadline)
        }
    }

    private func notify() {
        onSelectionChanged(viewModel.startDate, viewModel.endDate)
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.6).ignoresSafeArea()
        DatePickerView { start, end in
            print("start:", start as Any, "end:", end as Any)
        }
    }
}
