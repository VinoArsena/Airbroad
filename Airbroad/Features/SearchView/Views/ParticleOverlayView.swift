import SwiftUI

struct ParticleOverlayView: View {
    @Bindable var resViewModel: ResultViewModel
    @State private var particles: [AirParticle] = []
    
    var body: some View {
        GeometryReader { proxy in
            if resViewModel.shouldShowParticles {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let color = resViewModel.currentRiskLevel?.particleColor ?? .clear
                        
                        for particle in particles {
                            // Upward drifting motion
                            let rawY = (particle.y - time * particle.speed).truncatingRemainder(dividingBy: size.height)
                            let renderY = rawY < 0 ? rawY + size.height : rawY
                            
                            // Horizontal organic sway
                            let sway = sin(time * 1.5 + particle.driftFactor) * 14
                            let rawX = (particle.x + sway).truncatingRemainder(dividingBy: size.width)
                            let renderX = rawX < 0 ? rawX + size.width : rawX
                            
                            let rect = CGRect(
                                x: renderX,
                                y: renderY,
                                width: particle.size,
                                height: particle.size
                            )
                            
                            context.opacity = particle.opacity
                            context.fill(Path(ellipseIn: rect), with: .color(color))
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: resViewModel.currentRiskLevel)
        .onAppear {
            // Initial load
            particles = resViewModel.generateParticles(in: UIScreen.main.bounds.size)
        }
        .onChange(of: resViewModel.currentRiskLevel) { _, _ in
            particles = resViewModel.generateParticles(in: UIScreen.main.bounds.size)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
