import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        SearchView()
            .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
