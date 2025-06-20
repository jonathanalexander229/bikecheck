import SwiftUI

struct OnboardingTourOverlay: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            if let currentStep = onboardingViewModel.getCurrentTourStep() {
                // Tour card in fixed position
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentStep.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(currentStep.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    HStack {
                        Button("Skip Tour") {
                            onboardingViewModel.completeTour()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button(currentStep == .complete ? "Finish" : "Next") {
                            handleNextStep(currentStep)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.75 - 15)
                
                // Highlight box around the relevant tab
                if currentStep != .complete {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.9), lineWidth: 3)
                        )
                        .frame(width: 77, height: 55)
                        .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
                        .position(tabHighlightPosition(for: currentStep))
                }
            }
        }
        .onTapGesture {
            if let currentStep = onboardingViewModel.getCurrentTourStep() {
                handleNextStep(currentStep)
            }
        }
        .onAppear {
            // Navigate to appropriate tab when tour step changes
            if let currentStep = onboardingViewModel.getCurrentTourStep(),
               let tabName = currentStep.tabName {
                navigateToTab(tabName)
            }
        }
        .onChange(of: onboardingViewModel.currentTourStep) { _ in
            // Navigate to appropriate tab when tour step changes
            if let currentStep = onboardingViewModel.getCurrentTourStep(),
               let tabName = currentStep.tabName {
                navigateToTab(tabName)
            }
        }
    }
    
    private func handleNextStep(_ currentStep: TourStep) {
        withAnimation {
            onboardingViewModel.nextTourStep()
        }
    }
    
    private func navigateToTab(_ tabName: String) {
        withAnimation {
            switch tabName {
            case "Service Intervals":
                selectedTab = 0
            case "Bikes":
                selectedTab = 1
            case "Activities":
                selectedTab = 2
            default:
                break
            }
        }
    }
    
    private func tabHighlightPosition(for step: TourStep) -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let tabBarHeight: CGFloat = 120 // Height from bottom to tab center (moved up additional 15px)
        
        switch step {
        case .serviceIntervals:
            // Highlight first tab (Service Intervals) - adjusted for actual tab position
            let tabPosition = screenWidth * 0.167 // More precise first tab position
            return CGPoint(x: tabPosition, y: screenHeight - tabBarHeight)
        case .bikes:
            // Highlight second tab (Bikes) - center tab
            let tabPosition = screenWidth * 0.5
            return CGPoint(x: tabPosition, y: screenHeight - tabBarHeight)
        case .activities:
            // Highlight third tab (Activities) - adjusted for actual tab position
            let tabPosition = screenWidth * 0.833 // More precise third tab position
            return CGPoint(x: tabPosition, y: screenHeight - tabBarHeight)
        case .complete:
            return CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}