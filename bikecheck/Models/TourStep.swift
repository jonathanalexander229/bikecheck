enum TourStep: Int, CaseIterable {
    case serviceIntervals = 0
    case bikes = 1
    case activities = 2
    case complete = 3
    
    var title: String {
        switch self {
        case .serviceIntervals:
            return "Monitor Maintenance"
        case .bikes:
            return "Manage Your Fleet"
        case .activities:
            return "Track Your Rides"
        case .complete:
            return "Tour Complete!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .serviceIntervals:
            return "Keep track of when your bike components need service"
        case .bikes:
            return "View and manage your bikes and their details"
        case .activities:
            return "See your riding history and mileage"
        case .complete:
            return "Ready to connect your real data or explore more? Click Finish to return to the login screen."
        }
    }
    
    var tabName: String? {
        switch self {
        case .serviceIntervals:
            return "Service Intervals"
        case .bikes:
            return "Bikes"
        case .activities:
            return "Activities"
        case .complete:
            return nil
        }
    }
}