import Foundation
import Combine
import CoreData

class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        loadActivities()
    }
    
    func loadActivities() {
        isLoading = true
        activities = dataService.fetchActivities()
        isLoading = false
    }
    
    func getBikeName(for activity: Activity) -> String {
        let bikes = dataService.fetchBikes()
        return bikes.first(where: { $0.id == activity.gearId })?.name ?? "none"
    }
    
    func getFormattedDate(for activity: Activity) -> String {
        return DateFormatter.localizedString(from: activity.startDate, dateStyle: .medium, timeStyle: .none)
    }
    
    func getFormattedDuration(for activity: Activity) -> String {
        return String(format: "%.2f hours", Double(activity.movingTime) / 3600)
    }
    
    func getFormattedDistance(for activity: Activity) -> String {
        return String(format: "%.2f km", activity.distance / 1000)
    }
}