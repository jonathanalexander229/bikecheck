import Foundation
import BackgroundTasks
import os.log

/// A centralized manager for handling background tasks
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    // Background task identifiers
    enum TaskIdentifier: String, CaseIterable {
        case checkServiceInterval = "checkServiceInterval"
        case fetchActivities = "fetchActivities"
    }
    
    private let logger = Logger(subsystem: "com.bikecheck", category: "BackgroundTasks")
    
    // Thread safety
    private let taskQueue = DispatchQueue(label: "com.bikecheck.taskManager", attributes: .concurrent)
    
    // For testability - track task registration/scheduling
    private var _registeredTasks: Set<String> = []
    private var _scheduledTasks: [String: Date] = [:]
    private var _isTestingMode: Bool = false
    
    // Thread-safe accessors
    var registeredTasks: Set<String> {
        get {
            var result: Set<String> = []
            taskQueue.sync { result = self._registeredTasks }
            return result
        }
    }
    
    var scheduledTasks: [String: Date] {
        get {
            var result: [String: Date] = [:]
            taskQueue.sync { result = self._scheduledTasks }
            return result
        }
    }
    
    var isTestingMode: Bool {
        get {
            var result = false
            taskQueue.sync { result = self._isTestingMode }
            return result
        }
    }
    
    init() {
        // Default initializer
    }
    
    /// Enable testing mode - prevents real task scheduling
    func enableTestingMode() {
        taskQueue.async(flags: .barrier) { 
            self._isTestingMode = true
        }
        logger.info("Testing mode enabled - real task scheduling disabled")
    }
    
    /// Disable testing mode
    func disableTestingMode() {
        taskQueue.async(flags: .barrier) { 
            self._isTestingMode = false
        }
        logger.info("Testing mode disabled - real task scheduling enabled")
    }
    
    /// Initialize task tracking (without registering them)
    /// Note: Registration is handled by SwiftUI's .backgroundTask modifier
    func initializeTasks() {
        logger.info("Initializing background task tracking")
        
        // Track tasks for management purposes - use barrier to ensure thread safety
        taskQueue.async(flags: .barrier) {
            for task in TaskIdentifier.allCases {
                self._registeredTasks.insert(task.rawValue)
                self.logger.info("Initialized tracking for task: \(task.rawValue)")
            }
        }
    }
    
    /// Schedule a background task
    /// - Parameters:
    ///   - identifier: The task identifier to schedule
    ///   - delay: The delay in minutes before the task should run
    func scheduleBackgroundTask(identifier: TaskIdentifier, delay: Int = 6) {
        let taskId = identifier.rawValue
        logger.info("Scheduling background task: \(taskId)")
        
        // Get current testing mode status safely
        let testMode = isTestingMode
        
        // For testing, we might want to skip actual scheduling
        if testMode {
            let mockDate = Calendar.current.date(byAdding: .minute, value: delay, to: Date())!
            
            // Thread-safe update of scheduled tasks
            taskQueue.async(flags: .barrier) {
                self._scheduledTasks[taskId] = mockDate
            }
            
            logger.info("[TEST MODE] Simulated scheduling task: \(taskId) for \(mockDate)")
            return
        }
        
        // Real scheduling
        let request = BGAppRefreshTaskRequest(identifier: taskId)
        request.earliestBeginDate = Calendar.current.date(byAdding: .minute, value: delay, to: Date())
        
        do {
            try BGTaskScheduler.shared.submit(request)
            
            // Thread-safe update of scheduled tasks
            taskQueue.async(flags: .barrier) {
                self._scheduledTasks[taskId] = request.earliestBeginDate
            }
            
            logger.info("Successfully scheduled task: \(taskId)")
        } catch {
            logger.error("Failed to schedule background task: \(taskId), error: \(error.localizedDescription)")
        }
    }
    
    /// Schedule all background tasks
    func scheduleAllBackgroundTasks() {
        // Create a copy of the task identifiers to avoid mutation while enumerating
        let tasksToSchedule = Array(TaskIdentifier.allCases)
        for task in tasksToSchedule {
            scheduleBackgroundTask(identifier: task)
        }
    }
    
    /// This method is no longer used since task execution is handled by the app
    /// It's left here as a reference for future extensions of the framework
    private func handleBackgroundTask(_ task: BGTask) {
        // This method is no longer used - task execution is handled by app-level handlers
        logger.info("Task handler called, but execution is handled by app-level handlers: \(task.identifier)")
    }
    
    /// For testing: Check if a task is registered
    func isTaskRegistered(_ identifier: TaskIdentifier) -> Bool {
        // Thread-safe read
        return registeredTasks.contains(identifier.rawValue)
    }
    
    /// For testing: Get the scheduled date for a task (if available)
    func getScheduledDate(for identifier: TaskIdentifier) -> Date? {
        // Thread-safe read
        return scheduledTasks[identifier.rawValue]
    }
    
    /// For testing: Clear tracking data
    func resetForTesting() {
        // Thread-safe write
        taskQueue.async(flags: .barrier) {
            self._registeredTasks.removeAll()
            self._scheduledTasks.removeAll()
        }
        logger.info("Reset task manager tracking data for testing")
    }
}
