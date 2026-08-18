import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(CalendarViewModel.self) private var calViewModel
    var body: some View {
        SearchView()
            .environment(calViewModel)
    }
}

#Preview {
    ContentView()
        .environment(CalendarViewModel())
}
