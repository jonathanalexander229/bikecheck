import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    
    private let stravaService = StravaService.shared
    
    init() {}
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        isLoading = true
        stravaService.authenticate { success in
            self.isLoading = false
            completion(success)
        }
    }
    
    func insertTestData() {
        stravaService.insertTestData()
    }
    
    func clearTestData() {
        stravaService.clearTestData()
    }
}