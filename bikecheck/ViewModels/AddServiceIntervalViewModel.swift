import Foundation
import CoreData
import Combine

class AddServiceIntervalViewModel: ObservableObject {
    @Published var part = ""
    @Published var startTime: Double = 0
    @Published var intervalTime = ""
    @Published var notify = false
    @Published var selectedBike: Bike?
    @Published var bikes: [Bike] = []
    @Published var timeUntilServiceText: String = ""
    @Published var deleteConfirmationDialog = false
    @Published var resetConfirmationDialog = false
    @Published var showUnsavedChangesAlert = false
    
    // Original values for tracking changes
    private var originalPart = ""
    private var originalIntervalTime = ""
    private var originalNotify = false
    private var originalSelectedBike: Bike?
    
    private let context: NSManagedObjectContext
    
    var serviceInterval: ServiceInterval?
    
    init(serviceInterval: ServiceInterval? = nil, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.serviceInterval = serviceInterval
        self.context = context
        loadBikes()
        if let serviceInterval = serviceInterval {
            loadServiceIntervalData(serviceInterval)
        }
    }
    
    func loadBikes() {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        do {
            bikes = try context.fetch(fetchRequest)
            if selectedBike == nil && !bikes.isEmpty {
                selectedBike = bikes.first
            }
        } catch {
            print("Failed to fetch bikes: \(error)")
        }
    }
    
    private func loadServiceIntervalData(_ serviceInterval: ServiceInterval) {
        part = serviceInterval.part
        startTime = serviceInterval.startTime
        intervalTime = String(serviceInterval.intervalTime)
        notify = serviceInterval.notify
        selectedBike = serviceInterval.bike
        
        // Store original values for change tracking
        originalPart = part
        originalIntervalTime = intervalTime
        originalNotify = notify
        originalSelectedBike = selectedBike
        
        updateTimeUntilService()
    }
    
    var hasUnsavedChanges: Bool {
        guard serviceInterval != nil else {
            return false // Not in edit mode
        }
        
        return part != originalPart ||
               intervalTime != originalIntervalTime ||
               notify != originalNotify ||
               selectedBike != originalSelectedBike
    }
    
    func updateTimeUntilService() {
        guard let serviceInterval = serviceInterval, let selectedBike = selectedBike else { return }
        
        let totalRideTime = selectedBike.rideTime(context: context)
        let currentIntervalTime = totalRideTime - serviceInterval.startTime
        let timeUntilService = serviceInterval.intervalTime - currentIntervalTime
        
        timeUntilServiceText = String(format: "%.2f", timeUntilService)
    }
    
    func saveServiceInterval() {
        if let existingInterval = serviceInterval {
            updateExistingInterval(existingInterval)
        } else {
            createNewInterval()
        }
    }
    
    private func updateExistingInterval(_ interval: ServiceInterval) {
        interval.part = part
        interval.intervalTime = Double(intervalTime) ?? 0
        interval.notify = notify
        
        if let selectedBike = selectedBike {
            interval.bike = selectedBike
        }
        
        saveContext()
    }
    
    private func createNewInterval() {
        guard let selectedBike = selectedBike else { return }
        
        let newInterval = ServiceInterval(context: context)
        newInterval.part = part
        newInterval.intervalTime = Double(intervalTime) ?? 0
        newInterval.notify = notify
        newInterval.startTime = selectedBike.rideTime(context: context)
        newInterval.bike = selectedBike
        
        saveContext()
    }
    
    func resetInterval() {
        guard let serviceInterval = serviceInterval, let selectedBike = selectedBike else { return }
        
        serviceInterval.startTime = selectedBike.rideTime(context: context)
        timeUntilServiceText = String(format: "%.2f", serviceInterval.intervalTime)
        
        saveContext()
    }
    
    func deleteInterval() {
        guard let serviceInterval = serviceInterval else { return }
        
        context.delete(serviceInterval)
        saveContext()
    }
    
    func checkForChangesBeforeDismiss(completion: @escaping (Bool) -> Void) {
        if hasUnsavedChanges {
            showUnsavedChangesAlert = true
            completion(false) // Don't dismiss yet
        } else {
            completion(true) // Allow dismissal
        }
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}