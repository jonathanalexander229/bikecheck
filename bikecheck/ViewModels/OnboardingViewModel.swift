import Foundation
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var showOnboarding: Bool = false
    @Published var showTour: Bool = false
    @Published var currentTourStep: Int = 0
    @Published var isLoadingTestData: Bool = false
    
    private let stravaService = StravaService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func startOnboarding() {
        showOnboarding = true
    }
    
    func loadTestDataIfNeeded() {
        guard !isLoadingTestData else { return }
        
        isLoadingTestData = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Load test data but don't auto-sign in during onboarding
            self.stravaService.insertTestData(autoSignIn: false)
            
            DispatchQueue.main.async {
                self.isLoadingTestData = false
            }
        }
    }
    
    func startTour() {
        showOnboarding = false
        showTour = true
        currentTourStep = 0
        
        // Load test data and sign in when starting tour
        loadTestDataIfNeeded()
        DispatchQueue.main.async {
            self.stravaService.isSignedIn = true
        }
    }
    
    func skipTour() {
        showOnboarding = false
        showTour = false
        clearTestData()
    }
    
    func nextTourStep() {
        let tourSteps = TourStep.allCases
        if currentTourStep < tourSteps.count - 1 {
            currentTourStep += 1
        } else {
            completeTour()
        }
    }
    
    func completeTour() {
        showTour = false
        currentTourStep = 0
        
        // Clear test data and return to login when tour completes
        clearTestData()
    }
    
    private func clearTestData() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.stravaService.clearTestData()
        }
    }
    
    func clearTestDataIfNeeded() {
        // Clear test data and ensure user is signed out when returning to login
        DispatchQueue.main.async {
            self.stravaService.isSignedIn = false
        }
        clearTestData()
    }
    
    func getCurrentTourStep() -> TourStep? {
        let tourSteps = TourStep.allCases
        guard currentTourStep < tourSteps.count else { return nil }
        return tourSteps[currentTourStep]
    }
}