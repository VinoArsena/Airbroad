import SwiftUI

struct SplashView: View {
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .scaleEffect(isVisible ? 1.0 : 0.7)
                .opacity(isVisible ? 1.0 : 0.0)
        
            VStack(spacing: 10) {
                Text("Airbroad")
                    .font(.largeTitle.bold())
                Text("Air quality insights for university housing — plan ahead, breathe easier.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 64)
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 8)
            
            Spacer()
            Spacer()
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

#Preview {
    SplashView()
}
