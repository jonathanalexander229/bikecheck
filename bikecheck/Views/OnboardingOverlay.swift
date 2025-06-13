import SwiftUI

struct OnboardingOverlay: View {
    @State private var currentStep: Int = 0
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    let steps = OnboardingStep.allCases
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            if currentStep < steps.count {
                let step = steps[currentStep]
                
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
                        if step == .chooseExperience {
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
                        } else {
                            Spacer()
                            
                            Button("Next") {
                                withAnimation {
                                    if currentStep < steps.count - 1 {
                                        currentStep += 1
                                        
                                        // Load test data when moving to chooseExperience step
                                        let nextStep = steps[currentStep]
                                        if nextStep.shouldLoadTestData {
                                            onboardingViewModel.loadTestDataIfNeeded()
                                        }
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .position(tooltipPosition(for: step))
            }
        }
        .onTapGesture {
            let step = steps[currentStep]
            if step != .chooseExperience {
                withAnimation {
                    if currentStep < steps.count - 1 {
                        currentStep += 1
                        
                        // Load test data when moving to chooseExperience step  
                        let nextStep = steps[currentStep]
                        if nextStep.shouldLoadTestData {
                            onboardingViewModel.loadTestDataIfNeeded()
                        }
                    }
                }
            }
        }
        .onAppear {
            // Load test data immediately on welcome step
            let currentStepEnum = steps[currentStep]
            if currentStepEnum.shouldLoadTestData {
                onboardingViewModel.loadTestDataIfNeeded()
            }
        }
    }
    
    private func tooltipPosition(for step: OnboardingStep) -> CGPoint {
        switch step {
        case .welcome:
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: 300)
        case .chooseExperience:
            return CGPoint(x: UIScreen.main.bounds.width / 2, y: 400)
        }
    }
}