import Foundation
import Combine
import CoreData

class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadActivities()
    }
    
    func loadActivities() {
        isLoading = true
        
        let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest() as! NSFetchRequest<Activity>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.startDate, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "type == %@", "Ride")
        
        do {
            activities = try context.fetch(fetchRequest)
            isLoading = false
        } catch {
            print("Failed to fetch activities: \(error)")
            self.error = error
            isLoading = false
        }
    }
    
    func getBikeName(for activity: Activity) -> String {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        do {
            let bikes = try context.fetch(fetchRequest)
            return bikes.first(where: { $0.id == activity.gearId })?.name ?? "none"
        } catch {
            print("Failed to fetch bikes: \(error)")
            return "none"
        }
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