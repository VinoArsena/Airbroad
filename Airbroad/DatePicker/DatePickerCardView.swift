import SwiftUI

struct DatePickerCardView: View {
    let monthDate: Date
    @ObservedObject var viewModel: DatePickerViewModel
    let showsPreviousChevron: Bool
    let showsNextChevron: Bool

    private let weekdaySymbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayRow
            ForEach(Array(viewModel.weeks(for: monthDate).enumerated()), id: \.offset) { _, week in
                weekRow(week)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var header: some View {
        HStack {
            if showsPreviousChevron {
                Button { viewModel.goToPreviousMonth() } label: {
                    Image(systemName: "chevron.left")
                }
            } else {
                Color.clear.frame(width: 20)
            }

            Spacer()
            Text(monthDate, format: .dateTime.month(.wide).year())
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Spacer()

            if showsNextChevron {
                Button { viewModel.goToNextMonth() } label: {
                    Image(systemName: "chevron.right")
                }
            } else {
                Color.clear.frame(width: 20)
            }
        }
        .foregroundStyle(.secondary)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekRow(_ week: [DatePickerModel]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                DayCellView(day: day, viewModel: viewModel)
            }
        }
    }
}
