import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    
    private let stravaHelper: StravaHelper
    
    init(stravaHelper: StravaHelper) {
        self.stravaHelper = stravaHelper
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        isLoading = true
        stravaHelper.authenticate { success in
            self.isLoading = false
            completion(success)
        }
    }
    
    func insertTestData() {
        stravaHelper.insertTestData()
    }
}