import SwiftUI

struct OnboardingOverlay: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    let step = OnboardingStep.welcome
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(step.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(step.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.gray.opacity(0.9))
                .cornerRadius(12)
                
                HStack {
                    Button("Skip Tour") {
                        onboardingViewModel.skipTour()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Take the Tour") {
                        onboardingViewModel.startTour()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                }
            }
            .padding()
            .position(tooltipPosition(for: step))
        }
        .onAppear {
            // Load test data immediately on welcome step
            if step.shouldLoadTestData {
                onboardingViewModel.loadTestDataIfNeeded()
            }
        }
    }
    
    private func tooltipPosition(for step: OnboardingStep) -> CGPoint {
        switch step {
        case .welcome:
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: 350)
        }
    }
}