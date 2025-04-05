import Foundation
import Combine
import CoreData

class ServiceViewModel: ObservableObject {
    @Published var serviceIntervals: [ServiceInterval] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataService = DataService.shared
    private let stravaService = StravaService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        loadServiceIntervals()
    }
    
    func loadServiceIntervals() {
        isLoading = true
        serviceIntervals = dataService.fetchServiceIntervals()
        isLoading = false
    }
    
    func calculateTimeUntilService(for serviceInterval: ServiceInterval) -> Double {
        return stravaService.calculateTimeUntilService(for: serviceInterval)
    }
    
    func getTimeUntilServiceText(for serviceInterval: ServiceInterval) -> String {
        let timeUntilService = calculateTimeUntilService(for: serviceInterval)
        return String(format: "%.2f", timeUntilService)
    }
    
    func deleteInterval(serviceInterval: ServiceInterval) {
        context.delete(serviceInterval)
        dataService.saveContext()
        loadServiceIntervals()
    }
    
    func resetInterval(serviceInterval: ServiceInterval) {
        serviceInterval.startTime = serviceInterval.bike.rideTime(context: context)
        dataService.saveContext()
    }
}

