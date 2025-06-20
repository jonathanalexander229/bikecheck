enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to BikeCheck!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started."
        }
    }
    
    var shouldLoadTestData: Bool {
        switch self {
        case .welcome:
            return false
        }
    }
}