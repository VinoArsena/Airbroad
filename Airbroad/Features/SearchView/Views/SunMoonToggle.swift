import SwiftUI

struct SunMoonToggle: View {
    @Binding var isPM: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPM.toggle()
            }
        } label: {
            ZStack(alignment: isPM ? .trailing : .leading) {
                Capsule()
                    .fill(isPM ? Color(.lightGray) : Color(.blue.opacity(0.8)))
                    .frame(width: 50, height: 30)
                    .glassEffect()

                Circle()
                    .fill(.white)
                    .frame(width: 25, height: 25)
                    .overlay(
                        Image(systemName: isPM ? "moon.fill" : "sun.max.fill")
                            .font(.callout)
                            .foregroundStyle(isPM ? .black : .orange)
                    )
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SunMoonToggle(isPM: .constant(true))
}
