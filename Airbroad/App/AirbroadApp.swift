import SwiftUI
import SwiftData

@main
struct AirbroadApp: App {
    var body: some Scene {
        @State var calViewModel = CalendarViewModel()
        WindowGroup {
            ContentView()
                .environment(calViewModel)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}
