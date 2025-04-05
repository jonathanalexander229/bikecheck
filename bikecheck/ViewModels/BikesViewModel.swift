import SwiftUI
import CoreData

class BikesViewModel: ObservableObject {
    @Published var bikes: [Bike] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataService = DataService.shared
    
    init() {
        loadBikes()
    }
    
    func loadBikes() {
        isLoading = true
        bikes = dataService.fetchBikes()
        isLoading = false
    }
    
    func getTotalRideTime(for bike: Bike) -> String {
        return String(format: "%.2f hrs", bike.rideTime(context: PersistenceController.shared.container.viewContext))
    }
    
    func deleteBike(_ bike: Bike) {
        dataService.deleteBike(bike)
        loadBikes()
    }
    
    func createDefaultServiceIntervals(for bike: Bike) {
        dataService.createDefaultServiceIntervals(for: bike)
    }
}