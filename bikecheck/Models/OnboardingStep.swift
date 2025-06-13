enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case chooseExperience = 1
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to BikeCheck!"
        case .chooseExperience:
            return "Ready to explore BikeCheck?"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "Track your bike maintenance effortlessly"
        case .chooseExperience:
            return "Choose how you'd like to get started"
        }
    }
    
    var shouldLoadTestData: Bool {
        switch self {
        case .welcome:
            return true
        case .chooseExperience:
            return false
        }
    }
}