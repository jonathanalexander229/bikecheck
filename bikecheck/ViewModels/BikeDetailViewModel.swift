import Foundation
import Combine
import CoreData
import SwiftUI

class BikeDetailViewModel: ObservableObject {
    @Published var bike: Bike
    @Published var showingConfirmationDialog = false
    @Published var showingServiceIntervalsCreatedAlert = false
    
    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    init(bike: Bike) {
        self.bike = bike
    }
    
    func getTotalRideTime() -> String {
        return String(format: "%.2f", bike.rideTime(context: context))
    }
    
    func getActivityCount() -> Int {
        return bike.activities(context: context).count
    }
    
    func getMileage() -> String {
        return String(format: "%.2f", (bike.distance) * 0.000621371)
    }
    
    func deleteBike() {
        dataService.deleteBike(bike)
    }
    
    func createDefaultServiceIntervals() {
        dataService.createDefaultServiceIntervals(for: bike)
        showingServiceIntervalsCreatedAlert = true
    }
}