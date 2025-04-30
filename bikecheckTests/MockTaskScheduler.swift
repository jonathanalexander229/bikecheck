import Foundation
import BackgroundTasks
@testable import bikecheck

/// Mock BGTask for testing
class MockBGTask: BGTask {
    private let taskIdentifier: String
    private var completionCalled = false
    private var completionSuccess = false
    private var _expirationHandler: (() -> Void)?
    
    init(identifier: String) {
        self.taskIdentifier = identifier
    }
    
    override var identifier: String {
        return taskIdentifier
    }
    
    override var expirationHandler: (() -> Void)? {
        get {
            return _expirationHandler
        }
        set {
            _expirationHandler = newValue
        }
    }
    
    override func setTaskCompleted(success: Bool) {
        completionCalled = true
        completionSuccess = success
    }
    
    // Helper for tests
    var wasCompletionCalled: Bool {
        return completionCalled
    }
    
    var wasCompletedSuccessfully: Bool {
        return completionSuccess
    }
    
    func simulateExpiration() {
        _expirationHandler?()
    }
}

/// Mock BGTaskScheduler for testing
class MockBGTaskScheduler {
    // Singleton to replace BGTaskScheduler.shared during tests
    static let shared = MockBGTaskScheduler()
    
    // Tracking variables
    var registeredTasks: [String: (BGTask) -> Void] = [:]
    var submittedRequests: [BGTaskRequest] = []
    
    // Control flags
    var shouldFailSubmission = false
    var submissionError: Error?
    
    // Custom errors for testing
    enum MockError: Error {
        case simulatedFailure
    }
    
    // Mimics BGTaskScheduler API
    func register(forTaskWithIdentifier identifier: String, using queue: DispatchQueue?, launchHandler: @escaping (BGTask) -> Void) {
        registeredTasks[identifier] = launchHandler
    }
    
    func submit(_ request: BGTaskRequest) throws {
        if shouldFailSubmission {
            throw submissionError ?? MockError.simulatedFailure
        }
        
        submittedRequests.append(request)
    }
    
    // Helper methods for tests
    func isTaskRegistered(_ identifier: String) -> Bool {
        return registeredTasks.keys.contains(identifier)
    }
    
    func reset() {
        registeredTasks.removeAll()
        submittedRequests.removeAll()
        shouldFailSubmission = false
        submissionError = nil
    }
    
    // Simulate task launch
    func simulateTaskLaunch(identifier: String) {
        guard let handler = registeredTasks[identifier] else {
            return
        }
        
        let mockTask = MockBGTask(identifier: identifier)
        handler(mockTask)
    }
}

// Extension to help with testing
extension BackgroundTaskManager {
    /// Setup the manager for testing
    static func setupForTesting() {
        // Enable testing mode on the shared instance
        shared.enableTestingMode()
    }
    
    /// Restore the manager after testing
    static func tearDownAfterTesting() {
        // Disable testing mode on the shared instance
        shared.disableTestingMode()
        shared.resetForTesting()
    }
}
