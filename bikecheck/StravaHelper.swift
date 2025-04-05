//
//  StravaHelper.swift
//  BikeCheck
//

import Foundation
import AuthenticationServices
import Alamofire
import CoreData

class StravaHelper: ObservableObject {
    // MARK: - Published Properties
    @Published var isSignedIn = false
    @Published var tokenInfo: TokenInfo?
    @Published var athlete: Athlete?
    @Published var bikes: [Bike]?
    @Published var activities: [Activity]?
    
    // MARK: - Private Properties
    private var authSession: ASWebAuthenticationSession?
    private var managedObjectContext: NSManagedObjectContext
    
    private let urlScheme = "bikecheck"
    private let callbackUrl = "bikecheck-callback"
    private let clientSecret = "539be89a897a8f1096d36bb98182fdc9f08d211a"
    private let clientId = "54032"
    private let responseType = "code"
    private let scope = "read,profile:read_all,activity:read_all"
    
    // MARK: - Constants
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
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        loadSavedTokenInfo()
    }
    
    private func loadSavedTokenInfo() {
        let fetchRequest: NSFetchRequest<TokenInfo> = TokenInfo.fetchRequest() as! NSFetchRequest<TokenInfo>
        
        do {
            let tokenInfoResults = try managedObjectContext.fetch(fetchRequest)
            self.tokenInfo = tokenInfoResults.first
            self.isSignedIn = !tokenInfoResults.isEmpty
        } catch {
            print("\(ErrorMessages.fetchTokenFailed): \(error)")
            self.isSignedIn = false
        }
    }
    
    // MARK: - Authentication
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
    
    // MARK: - Token Management
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
                self.getAthlete { _ in }
                completion(true)
            } catch {
                print("Decoding or saving error: \(error)")
                completion(false)
            }
        }
    }
    
    func getAccessToken(completion: @escaping (String?) -> Void) {
        // If token is valid, return it immediately
        if let expiresAt = self.tokenInfo?.expiresAt,
           expiresAt > Int(Date().timeIntervalSince1970) {
            completion(self.tokenInfo?.accessToken)
            return
        }
        
        // Token expired, refresh it
        self.refreshAccessToken { newAccessToken in
            completion(newAccessToken)
        }
    }
    
    func refreshAccessToken(completion: @escaping (String?) -> Void) {
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
    
    // MARK: - API Calls
    func getAthlete(completion: @escaping (Result<Void, Error>) -> Void) {
        // Skip API calls in demo mode
        if isDemoMode() {
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
            
            AF.request(ApiEndpoints.athlete, headers: ["Authorization": "Bearer \(accessToken)"])
              .response(responseSerializer: responseSerializer) { response in
                  switch response.result {
                  case .success(_):
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
            
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)"]
            let parameters: [String: Any] = [
                "page": 1,
                "per_page": 5,
                "type": "Ride"
            ]
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
            let responseSerializer = DecodableResponseSerializer<[Activity]>(decoder: decoder)
            
            AF.request(ApiEndpoints.activities, parameters: parameters, headers: headers)
                .validate(statusCode: 200..<300)
                .response(responseSerializer: responseSerializer) { [weak self] response in
                    guard let self = self else { return }
                    
                    switch response.result {
                    case .success(let activities):
                        self.bikes = self.getBikes()
                        self.activities = activities
                        
                        do {
                            try self.managedObjectContext.save()
                            completion(.success(()))
                        } catch {
                            print(ErrorMessages.saveFailed + ": \(error)")
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        }
    }
    
    // MARK: - Data Management
    func getBikes() -> [Bike] {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        
        do {
            let bikes = try self.managedObjectContext.fetch(fetchRequest)
            return bikes
        } catch {
            print("\(ErrorMessages.fetchBikesFailed): \(error)")
            return []
        }
    }
    
    func fetchServiceIntervals() -> [ServiceInterval] {
        let fetchRequest: NSFetchRequest<ServiceInterval> = ServiceInterval.fetchRequest() as! NSFetchRequest<ServiceInterval>
        
        do {
            return try self.managedObjectContext.fetch(fetchRequest)
        } catch {
            print("\(ErrorMessages.fetchIntervalsFailed): \(error)")
            return []
        }
    }
    
    func calculateTimeUntilService(for servInt: ServiceInterval) -> Double {
        let totalRideTime = servInt.bike.rideTime(context: self.managedObjectContext)
        let startTime = servInt.startTime
        let intervalTime = servInt.intervalTime
        
        return intervalTime - (totalRideTime - startTime)
    }
    
    func checkServiceIntervals() {
        let serviceIntervals = fetchServiceIntervals()
        let notificationManager = NotificationManager()
        
        serviceIntervals.forEach { interval in
            if interval.bike.rideTime(context: self.managedObjectContext) >= interval.intervalTime {
                notificationManager.sendNotification(for: interval)
            }
        }
    }
    
    // MARK: - Test Data
    private func isDemoMode() -> Bool {
        return self.tokenInfo?.expiresAt == 9999999999
    }
    
    func insertTestData() {
        let viewContext = managedObjectContext
        
        // Create token and athlete
        let newTokenInfo = TokenInfo(context: viewContext)
        newTokenInfo.accessToken = "953ff94ea69feea5cc5521e2d44abeea242dd3ae"
        newTokenInfo.refreshToken = "447b364e34d996523d72370f509973f51934f5c5"
        newTokenInfo.expiresAt = 9999999999  // Demo mode flag
        
        let newAthlete = Athlete(context: viewContext)
        newAthlete.firstname = "testuser"
        newAthlete.id = 26493868
        
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
                self.isSignedIn = true
                self.tokenInfo = newTokenInfo
                self.athlete = newAthlete
                self.bikes = bikes
            }
        } catch {
            print("Failed to save test data: \(error)")
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
}

// MARK: - Auth Presentation Context Provider
extension StravaHelper {
    class AuthenticationSession: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first(where: { 
                $0.activationState == .foregroundActive && $0 is UIWindowScene 
            }) as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("Could not find appropriate window for authentication")
            }
            
            return window
        }
    }
}
