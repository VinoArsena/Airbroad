import SwiftUI

struct DayCellView: View {
    let day: DatePickerModel
    @ObservedObject var viewModel: DatePickerViewModel

    var body: some View {
        Button {
            if let date = day.date {
                viewModel.select(date)
            }
        } label: {
            Text("\(day.dayNumber)")
                .font(.footnote)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(background)
        }
        .disabled(day.date == nil)
        .buttonStyle(.plain)
    }

    private var isSelectedEdge: Bool {
        guard let date = day.date else { return false }
        return viewModel.isStart(date) || viewModel.isEnd(date)
    }

    private var isMiddleOfRange: Bool {
        guard let date = day.date else { return false }
        return viewModel.isInRange(date) && !isSelectedEdge
    }

    private var textColor: Color {
        guard day.isCurrentMonth else { return .secondary.opacity(0.4) }
        return isSelectedEdge ? .white : .primary
    }

    @ViewBuilder
    private var background: some View {
        if let date = day.date, isSelectedEdge {
            let isStart = viewModel.isStart(date)
            let isEnd = viewModel.isEnd(date)
            UnevenRoundedRectangle(
                topLeadingRadius: isStart ? 17 : 0,
                bottomLeadingRadius: isStart ? 17 : 0,
                bottomTrailingRadius: isEnd ? 17 : 0,
                topTrailingRadius: isEnd ? 17 : 0
            )
            .fill(Color.accentColor)
        } else if isMiddleOfRange {
            Rectangle()
                .fill(Color.accentColor.opacity(0.15))
        } else {
            Color.clear
        }
    }
}


