import Foundation

struct DatePickerModel: Identifiable, Hashable {
    let id = UUID()
    let date: Date?          // nil = padding cell from adjacent month
    let dayNumber: Int
    let isCurrentMonth: Bool
}
