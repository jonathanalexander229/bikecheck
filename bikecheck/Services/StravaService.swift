import Foundation
import CoreData
import Alamofire
import AuthenticationServices
import Combine
import UIKit

class StravaService: ObservableObject {
    // Use static let + closure pattern to ensure that shared is initialized exactly once
    // and the initialization happens when the class is first accessed
    static let shared: StravaService = {
        let instance = StravaService()
        // Initialization is performed in the init method
        return instance
    }()
    
    @Published var isSignedIn: Bool?
    @Published var tokenInfo: TokenInfo?
    @Published var athlete: Athlete?
    @Published var bikes: [Bike]?
    @Published var activities: [Activity]?
    @Published var profileImage: UIImage?
    
    private var managedObjectContext: NSManagedObjectContext
    private var authSession: ASWebAuthenticationSession?
    
    private let urlScheme: String = "bikecheck"
    private let callbackUrl: String = "bikecheck-callback"
    private let clientSecret: String = "539be89a897a8f1096d36bb98182fdc9f08d211a"
    private let clientId: String = "54032"
    private let responseType = "code"
    private let scope = "read,profile:read_all,activity:read_all"
    
    private enum ApiEndpoints {
        static let token = "https://www.strava.com/oauth/token"
        static let athlete = "https://www.strava.com/api/v3/athlete"
        static let activities = "https://www.strava.com/api/v3/athlete/activities"
        static let oauthMobile = "https://www.strava.com/oauth/mobile/authorize"
    }
    
    private enum ErrorMessages {
        static let fetchTokenFailed = "Failed to fetch TokenInfo"
        static let fetchBikesFailed = "Failed to fetch bikes"
        static let fetchIntervalsFailed = "Failed to fetch ServiceInterval objects"
        static let accessTokenFailed = "Failed to get access token"
        static let saveFailed = "Failed to save managed object context"
    }
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.managedObjectContext = context
        checkAuthentication()
    }
    
    private func checkAuthentication() {
        let fetchRequest: NSFetchRequest<TokenInfo> = TokenInfo.fetchRequest() as! NSFetchRequest<TokenInfo>
        
        do {
            let tokenInfo = try managedObjectContext.fetch(fetchRequest)
            self.tokenInfo = tokenInfo.first
            self.isSignedIn = !tokenInfo.isEmpty
            
            if !tokenInfo.isEmpty {
                self.fetchAthleteData()
            }
        } catch {
            print("Failed to fetch TokenInfo: \(error)")
            self.isSignedIn = false
        }
    }
    
    func fetchAthleteData() {
        self.getAthlete { _ in }
        self.fetchActivities { _ in }
        
        if let urlString = self.athlete?.profile, let url = URL(string: urlString) {
            self.loadProfileImage(from: url)
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        guard let authUrl = URL(string: "\(ApiEndpoints.oauthMobile)?client_id=\(clientId)&redirect_uri=\(urlScheme)%3A%2F%2F\(callbackUrl)&response_type=\(responseType)&approval_prompt=auto&scope=\(scope)") else {
            completion(false)
            return
        }
        
        let callback: ASWebAuthenticationSession.CompletionHandler = { [weak self] url, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleAuthError(error, completion: completion)
                return
            }
            
            guard let url = url, let authorizationCode = self.getCode(from: url) else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            self.requestStravaTokens(with: authorizationCode) { success in
                DispatchQueue.main.async {
                    self.isSignedIn = success
                    if success {
                        self.fetchAthleteData()
                    }
                    completion(success)
                }
            }
        }
        
        if UIApplication.shared.canOpenURL(authUrl) {
            UIApplication.shared.open(authUrl, options: [:])
        } else {
            let contextProvider = AuthenticationSession()
            authSession = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: urlScheme, completionHandler: callback)
            authSession?.presentationContextProvider = contextProvider
            authSession?.start()
        }
    }
    
    private func handleAuthError(_ error: Error, completion: @escaping (Bool) -> Void) {
        if let authError = error as? ASWebAuthenticationSessionError, 
           authError.code == .canceledLogin {
            print("User canceled the login process.")
        } else {
            print("Authentication error: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            completion(false)
        }
    }
    
    private func getCode(from url: URL?) -> String? {
        guard let absoluteString = url?.absoluteString,
              let urlComponents = URLComponents(string: absoluteString) else { 
            return nil 
        }
        
        return urlComponents.queryItems?.first(where: { $0.name == "code" })?.value
    }
    
    func requestStravaTokens(with code: String, completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = [
            "client_id": clientId, 
            "client_secret": clientSecret, 
            "code": code, 
            "grant_type": "authorization_code"
        ]
        
        AF.request(ApiEndpoints.token, method: .post, parameters: parameters).response { [weak self] response in
            guard let self = self,
                  let data = response.data else {
                completion(false)
                return
            }
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
            
            do {
                self.tokenInfo = try decoder.decode(TokenInfo.self, from: data)
                try self.managedObjectContext.save()
                completion(true)
            } catch {
                print("Decoding or saving error: \(error)")
                completion(false)
            }
        }
    }
    
    func getAccessToken(completion: @escaping (String?) -> Void) {
        if (self.tokenInfo?.expiresAt ?? 0) > Int(Date().timeIntervalSince1970) {
            completion(self.tokenInfo?.accessToken)
        } else {
            self.refreshAccessToken { newAccessToken in
                completion(newAccessToken)
            }
        }
    }
    
    private func refreshAccessToken(completion: @escaping (String?) -> Void) {
        guard let refreshToken = self.tokenInfo?.refreshToken else {
            completion(nil)
            return
        }
        
        let parameters: [String: Any] = [
            "client_id": clientId, 
            "client_secret": clientSecret, 
            "grant_type": "refresh_token", 
            "refresh_token": refreshToken
        ]
        
        AF.request(ApiEndpoints.token, method: .post, parameters: parameters).response { [weak self] response in
            guard let self = self,
                  let data = response.data else {
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
                let newTokenInfo = try decoder.decode(TokenInfo.self, from: data)
                
                self.tokenInfo?.accessToken = newTokenInfo.accessToken
                self.tokenInfo?.refreshToken = newTokenInfo.refreshToken
                self.tokenInfo?.expiresAt = newTokenInfo.expiresAt
                try self.managedObjectContext.save()
                completion(self.tokenInfo?.accessToken)
            } catch {
                print("Failed to decode refreshed token info: \(error)")
                completion(nil)
            }
        }
    }
    
    func getAthlete(completion: @escaping (Result<Void, Error>) -> Void) {
        // Skip API calls in demo mode
        if isDemoMode() {
            print("Demo Mode - Using existing athlete")
            // In demo mode, check if we have a valid athlete already
            if let athlete = self.athlete {
                print("Using existing athlete in demo mode: \(athlete.firstname), profile URL: \(athlete.profile ?? "none")")
                
                // Load profile image if available
                if let urlString = athlete.profile, let url = URL(string: urlString) {
                    self.loadProfileImage(from: url)
                }
                
            } else {
                print("No athlete found in demo mode, setting a default athlete")
                let newAthlete = Athlete(context: managedObjectContext)
                newAthlete.firstname = "Demo User"
                newAthlete.id = 26493868
                newAthlete.profile = "https://dgalywyr863hv.cloudfront.net/pictures/athletes/26493868/8338609/1/large.jpg"
                self.athlete = newAthlete
                
                // Load the default profile image
                if let url = URL(string: newAthlete.profile!) {
                    self.loadProfileImage(from: url)
                }
                
                do {
                    try managedObjectContext.save()
                    print("Saved demo athlete data")
                } catch {
                    print("Error saving demo athlete data: \(error)")
                }
            }
            completion(.success(()))
            return
        }
        
        getAccessToken { [weak self] accessToken in
            guard let self = self else { return }
            guard let accessToken = accessToken else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.accessTokenFailed])
                completion(.failure(error))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
            
            let responseSerializer = DecodableResponseSerializer<Athlete>(decoder: decoder)
            
            AF.request(ApiEndpoints.athlete, headers: ["Authorization": "Bearer \(accessToken)"]).response(responseSerializer: responseSerializer) { response in
                switch response.result {
                case .success(let athlete):
                    self.athlete = athlete
                    
                    // Load profile image if available
                    if let urlString = athlete.profile, let url = URL(string: urlString) {
                        self.loadProfileImage(from: url)
                    }
                    
                    do {
                        try self.managedObjectContext.save()
                        completion(.success(()))
                    } catch {
                        print("Error saving athlete data: \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("API error fetching athlete: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        // Skip API calls in demo mode
        if isDemoMode() {
            print("Demo Mode - Creating test bikes and activities")
            
            // Check if we already have demo bikes and activities
            let bikes = getBikes()
            if bikes.isEmpty {
                // Create test bikes
                let demoBikes = [
                    createBike(id: "b1", name: "Kenevo", distance: 99999, in: managedObjectContext),
                    createBike(id: "b2", name: "StumpJumper", distance: 99999, in: managedObjectContext),
                    createBike(id: "b3", name: "Checkpoint", distance: 99999, in: managedObjectContext),
                    createBike(id: "b4", name: "TimberJACKED", distance: 99999, in: managedObjectContext)
                ]
                
                // Create activities for the first bike
                createActivity(id: 1111111, gearId: "b1", speed: 12.05, time: 645, name: "Test Activity 1", daysAgo: 5, in: managedObjectContext)
                createActivity(id: 2222222, gearId: "b1", speed: 15.06, time: 1585, name: "Test Activity 2", daysAgo: 3, in: managedObjectContext)
                createActivity(id: 3333333, gearId: "b1", speed: 9.03, time: 2765, name: "Test Activity 3", daysAgo: 6, in: managedObjectContext)
                
                // Create service intervals for the first bike
                createServiceInterval(part: "chain", interval: 5, bike: demoBikes[0], in: managedObjectContext)
                createServiceInterval(part: "Fork Lowers", interval: 10, bike: demoBikes[0], in: managedObjectContext)
                createServiceInterval(part: "Shock", interval: 15, bike: demoBikes[0], in: managedObjectContext)
                
                // Save changes
                do {
                    try managedObjectContext.save()
                    self.bikes = demoBikes
                } catch {
                    print("Failed to save demo data: \(error)")
                }
            } else {
                self.bikes = bikes
            }
            
            // Load activities
            let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest() as! NSFetchRequest<Activity>
            do {
                self.activities = try managedObjectContext.fetch(fetchRequest)
            } catch {
                print("Failed to fetch activities: \(error)")
            }
            
            completion(.success(()))
            return
        }
        
        getAccessToken { [weak self] accessToken in
            guard let self = self else { return }
            guard let accessToken = accessToken else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: ErrorMessages.accessTokenFailed])
                completion(.failure(error))
                return
            }
            
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(accessToken)"
            ]
            
            let parameters: [String: Any] = [
                "page": 1,
                "per_page": 30,
                "type": "Ride"
            ]
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
            
            let responseSerializer = DecodableResponseSerializer<[Activity]>(decoder: decoder)
            
            AF.request(ApiEndpoints.activities, parameters: parameters, headers: headers)
                .validate(statusCode: 200..<300)
                .response(responseSerializer: responseSerializer, completionHandler: { response in
                    switch response.result {
                    case .success(let activities):
                        self.activities = activities
                        self.bikes = self.getBikes()
                        do {
                            try self.managedObjectContext.save()
                            completion(.success(()))
                        } catch {
                            print("Failed to save managed object context: \(error)")
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
        }
    }
    
    func getBikes() -> [Bike] {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        do {
            let bikes = try self.managedObjectContext.fetch(fetchRequest)
            return bikes
        } catch {
            print("Failed to fetch bikes: \(error)")
            return []
        }
    }
    
    func checkServiceIntervals() async {
        // First create a completely separate copy of service intervals 
        let serviceIntervals = await MainActor.run { self.fetchServiceIntervals() }
        
        // Clone intervals into a simple array to avoid NSSet mutation issues
        let intervalsCopy = await MainActor.run { Array(serviceIntervals) }
        
        // Process each interval - split into two steps to avoid Core Data conflicts
        for interval in intervalsCopy {
            let timeUntilService = await MainActor.run { self.calculateTimeUntilService(for: interval) }
            
            if timeUntilService <= 0 && interval.notify {
                // Send notification on the main thread
                await MainActor.run {
                    NotificationService.shared.sendNotification(for: interval)
                }
            }
        }
    }
    
    func fetchServiceIntervals() -> [ServiceInterval] {
        let fetchRequest: NSFetchRequest<ServiceInterval> = ServiceInterval.fetchRequest() as! NSFetchRequest<ServiceInterval>
        do {
            let serviceIntervals = try self.managedObjectContext.fetch(fetchRequest)
            return serviceIntervals
        } catch {
            print("Failed to fetch ServiceInterval objects: \(error)")
            return []
        }
    }
    
    func calculateTimeUntilService(for serviceInterval: ServiceInterval) -> Double {
        let totalRideTime = serviceInterval.bike.rideTime(context: self.managedObjectContext)
        let startTime = serviceInterval.startTime
        let intervalTime = serviceInterval.intervalTime
        
        let currentIntervalTime = totalRideTime - startTime
        return intervalTime - currentIntervalTime
    }
    
    // MARK: - Test Data
    private func isDemoMode() -> Bool {
        return self.tokenInfo?.expiresAt == 9999999999
    }
    
    func insertTestData(autoSignIn: Bool = true) {
        let viewContext = managedObjectContext
        
        // Create token and athlete
        let newTokenInfo = TokenInfo(context: viewContext)
        newTokenInfo.accessToken = "953ff94ea69feea5cc5521e2d44abeea242dd3ae"
        newTokenInfo.refreshToken = "447b364e34d996523d72370f509973f51934f5c5"
        newTokenInfo.expiresAt = 9999999999  // Demo mode flag
        
        let newAthlete = Athlete(context: viewContext)
        newAthlete.firstname = "testuser"
        newAthlete.id = 26493868
        newAthlete.profile = "https://dgalywyr863hv.cloudfront.net/pictures/athletes/26493868/8338609/1/large.jpg"
        
        // Create bikes
        let bikes = [
            createBike(id: "b1", name: "Kenevo", distance: 99999, in: viewContext),
            createBike(id: "b2", name: "StumpJumper", distance: 99999, in: viewContext),
            createBike(id: "b3", name: "Checkpoint", distance: 99999, in: viewContext),
            createBike(id: "b4", name: "TimberJACKED", distance: 99999, in: viewContext)
        ]
        
        // Create activities for the first bike
        createActivity(id: 1111111, gearId: "b1", speed: 12.05, time: 645, name: "Test Activity 1", daysAgo: 5, in: viewContext)
        createActivity(id: 2222222, gearId: "b1", speed: 15.06, time: 1585, name: "Test Activity 2", daysAgo: 3, in: viewContext)
        createActivity(id: 3333333, gearId: "b1", speed: 9.03, time: 2765, name: "Test Activity 3", daysAgo: 6, in: viewContext)
        
        // Create service intervals for the first bike
        createServiceInterval(part: "chain", interval: 5, bike: bikes[0], in: viewContext)
        createServiceInterval(part: "Fork Lowers", interval: 10, bike: bikes[0], in: viewContext)
        createServiceInterval(part: "Shock", interval: 15, bike: bikes[0], in: viewContext)
        
        // Set relationships
        newAthlete.bikes = NSSet(array: bikes) as! Set<Bike>
        newTokenInfo.athlete = newAthlete
        
        // Save the context
        do {
            try viewContext.save()
            DispatchQueue.main.async {
                if autoSignIn {
                    self.isSignedIn = true
                }
                self.tokenInfo = newTokenInfo
                self.athlete = newAthlete
                self.bikes = bikes
            }
        } catch {
            print("Failed to save test data: \(error)")
        }
    }
    
    func clearTestData() {
        let viewContext = managedObjectContext
        
        // Create fetch requests for all entities
        let bikeRequest: NSFetchRequest<NSFetchRequestResult> = Bike.fetchRequest()
        let activityRequest: NSFetchRequest<NSFetchRequestResult> = Activity.fetchRequest()
        let serviceIntervalRequest: NSFetchRequest<NSFetchRequestResult> = ServiceInterval.fetchRequest()
        let athleteRequest: NSFetchRequest<NSFetchRequestResult> = Athlete.fetchRequest()
        let tokenRequest: NSFetchRequest<NSFetchRequestResult> = TokenInfo.fetchRequest()
        
        // Create batch delete requests
        let bikesDelete = NSBatchDeleteRequest(fetchRequest: bikeRequest)
        let activitiesDelete = NSBatchDeleteRequest(fetchRequest: activityRequest)
        let serviceIntervalsDelete = NSBatchDeleteRequest(fetchRequest: serviceIntervalRequest)
        let athleteDelete = NSBatchDeleteRequest(fetchRequest: athleteRequest)
        let tokenDelete = NSBatchDeleteRequest(fetchRequest: tokenRequest)
        
        do {
            // Execute batch deletes
            try viewContext.execute(serviceIntervalsDelete)
            try viewContext.execute(activitiesDelete)
            try viewContext.execute(bikesDelete)
            try viewContext.execute(athleteDelete)
            try viewContext.execute(tokenDelete)
            
            // Save context
            try viewContext.save()
            
            // Reset published properties
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.tokenInfo = nil
                self.athlete = nil
                self.bikes = nil
                self.activities = nil
                self.profileImage = nil
            }
            
        } catch {
            print("Failed to clear test data: \(error)")
        }
    }
    
    // Helper methods for creating test data
    private func createBike(id: String, name: String, distance: Int, in context: NSManagedObjectContext) -> Bike {
        let bike = Bike(context: context)
        bike.id = id
        bike.name = name
        bike.distance = Double(distance)
        return bike
    }
    
    private func createActivity(id: Int, gearId: String, speed: Double, time: Int, name: String, daysAgo: Int, in context: NSManagedObjectContext) {
        let activity = Activity(context: context)
        activity.id = Int64(id)
        activity.gearId = gearId
        activity.averageSpeed = speed
        activity.movingTime = Int64(time)
        activity.name = name
        activity.startDate = Date().advanced(by: Double(-daysAgo * 86400))
        activity.type = "Ride"
    }
    
    private func createServiceInterval(part: String, interval: Int, bike: Bike, in context: NSManagedObjectContext) {
        let serviceInterval = ServiceInterval(context: context)
        serviceInterval.part = part
        serviceInterval.intervalTime = Double(interval)
        serviceInterval.startTime = 0
        serviceInterval.bike = bike
        serviceInterval.notify = true
    }
    
    class AuthenticationSession: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive && $0 is UIWindowScene }) as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("Unable to find an active window")
            }
            
            return window
        }
    }
}
