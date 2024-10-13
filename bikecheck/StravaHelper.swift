//
//  StravaAuth.swift
//  BikeCheck
//
//  Created by clutchcoder on 12/25/23.
//

import Foundation
import AuthenticationServices
import Alamofire
import CoreData

class StravaHelper: ObservableObject {
        
    //static let shared = StravaAuth()
    @Published var isSignedIn: Bool?
    @Published var tokenInfo: TokenInfo?
    @Published var athlete: Athlete?
    @Published var bikes: [Bike]?
    @Published var activities: [Activity]?
    
    var managedObjectContext: NSManagedObjectContext
    
    private var authSession: ASWebAuthenticationSession?
    //var lastActivity: Activity?
    
    private let urlScheme: String = "bikecheck"
    private let callbackUrl: String = "bikecheck-callback"
    private let clientSecret: String = "539be89a897a8f1096d36bb98182fdc9f08d211a"
    private let clientId: String = "54032"
    private let responseType = "code"
    private let scope = "read,profile:read_all,activity:read_all"

    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        let fetchRequest: NSFetchRequest<TokenInfo> = TokenInfo.fetchRequest() as! NSFetchRequest<TokenInfo>
        
        do {
            let tokenInfo  = try context.fetch(fetchRequest)
            self.tokenInfo = tokenInfo.first
            self.isSignedIn = !tokenInfo.isEmpty
            
        } catch {
            print("Failed to fetch TokenInfo: \(error)")
            self.isSignedIn = false
        }
    }

    func authenticate(completion: @escaping (Bool) -> Void) {
        let commonUrl = "oauth/mobile/authorize?client_id=\(clientId)&redirect_uri=\(urlScheme)%3A%2F%2F\(callbackUrl)&response_type=\(responseType)&approval_prompt=auto&scope=\(scope)"
        let appOAuthUrlStravaScheme = URL(string: "strava://\(commonUrl)")!
        //let webOAuthUrl = URL(string: "https://www.strava.com/\(commonUrl)")!
        
        let weburl = URL(string: "https://www.strava.com/oauth/mobile/authorize?client_id=\(clientId)&redirect_uri=\(urlScheme)%3A%2F%2F\(callbackUrl)&response_type=\(responseType)&approval_prompt=auto&scope=\(scope)")!
        
        let callback: ASWebAuthenticationSession.CompletionHandler = { url, error in
            // Handle the authentication result
            if let error = error {
                // Use pattern matching to check if the error is a cancellation error
                if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                    print("User canceled the login process.")
                    DispatchQueue.main.async {
                        completion(false) // Indicate cancellation or failure to the completion handler
                    }
                } else {
                    print("Authentication error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(false) // Handle other errors
                    }
                }
            } else if let url = url, let authorizationCode = self.getCode(from: url) {
                print(authorizationCode)
                self.requestStravaTokens(with: authorizationCode) { success in
                    DispatchQueue.main.async {
                        self.isSignedIn = success
                        completion(success) // Indicate success to the completion handler
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false) // Handle the case where URL is nil
                }
            }
        }

        if UIApplication.shared.canOpenURL(appOAuthUrlStravaScheme) {
            UIApplication.shared.open(appOAuthUrlStravaScheme, options: [:])
        } else {
            let contextProvider = AuthenticationSession()
            authSession = ASWebAuthenticationSession(url: weburl, callbackURLScheme: "bikecheck", completionHandler: callback)
            authSession?.presentationContextProvider = contextProvider
            authSession?.start()
        }
    }
    
    func getCode(from url: URL?) -> String? {
        guard let url = url?.absoluteString else { return nil }
        
        let urlComponents: URLComponents? = URLComponents(string: url)
        let code: String? = urlComponents?.queryItems?.filter { $0.name == "code" }.first?.value
        
        return code
    }

    func requestStravaTokens(with code: String, completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = ["client_id": clientId, "client_secret": clientSecret, "code": code, "grant_type": "authorization_code"]

        AF.request("https://www.strava.com/oauth/token", method: .post, parameters: parameters).response { response in
            guard let data = response.data else {
                completion(false)
                return
            }
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext

            do {
                self.tokenInfo = try decoder.decode(TokenInfo.self, from: data)
                try self.managedObjectContext.save()
                self.getAthlete()  { _ in }
                completion(true)
            } catch {
                print("Decoding or saving error: \(error)")
                completion(false)
            }
        }
    }

    func getAccessToken(completion: @escaping (String?) -> Void) {
        // Check if the current time is past the access token's expiration time
        if  (self.tokenInfo?.expiresAt ?? 0) > Int(Date().timeIntervalSince1970) {
            // If the access token is still valid, return it
            completion(self.tokenInfo?.accessToken)
        } else {
            print("access token expired")
            // If the access token has expired, refresh it
            self.refreshAccessToken { newAccessToken in
                completion(newAccessToken)
            }
        }
    }

    func refreshAccessToken(completion: @escaping (String?) -> Void) {
        guard let refreshToken = self.tokenInfo?.refreshToken else {
            completion(nil)
            return
        }
        
        let parameters: [String: Any] = ["client_id": clientId, "client_secret": clientSecret, "grant_type": "refresh_token", "refresh_token": refreshToken]
        
        AF.request("https://www.strava.com/oauth/token", method: .post, parameters: parameters).response { response in
            guard let data = response.data else {
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

    func  getAthlete(completion: @escaping (Result<Void, Error>) -> Void) {
        getAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get access token"])))
                return
            
            }
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext

            let responseSerializer = DecodableResponseSerializer<Athlete>(decoder: decoder)

            AF.request("https://www.strava.com/api/v3/athlete", headers: ["Authorization": "Bearer \(accessToken)"]).response(responseSerializer: responseSerializer) { response in
                switch response.result {
                case .success(_):
                    do {
                        try self.managedObjectContext.save()
                        completion(.success(()))
                    } catch {
                        print(error)
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print(error)
                    completion(.failure(error))
                }
            }
            
            
        }
    }

    func getBikes() -> [Bike] {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
       // fetchRequest.returnsObjectsAsFaults = false
        do {
            let bikes = try self.managedObjectContext.fetch(fetchRequest)
           // print("Fetched \(bikes.count) bikes")
            return bikes
        } catch {
            print("Failed to fetch bikes: \(error)")
            return []
        }
    }

    func calculateTimeUntilService(for servInt: ServiceInterval) -> Double {
        // This is a placeholder implementation. Replace it with your actual calculation.
        let totalRideTime = servInt.bike.rideTime(context: self.managedObjectContext) 
        let startTime = servInt.startTime
        let intervalTime = servInt.intervalTime

        let currentIntervalTime = totalRideTime - startTime
        let timeUntilService = intervalTime - currentIntervalTime
        return timeUntilService
    }

    func checkServiceIntervals() {
        let serviceIntervals = fetchServiceIntervals()

        serviceIntervals.forEach { interval in
            let rideTime = interval.bike.rideTime(context: self.managedObjectContext)
            if rideTime >= interval.intervalTime {
                // Send notification
                NotificationManager().sendNotification(for: interval)
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



    func fetchActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        getAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get access token"])))
                return
            }
            
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(accessToken)"
            ]
            
            let parameters: [String: Any] = [
                "page": 1,
                "per_page": 5,
                "type": "Ride"
            ]
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
            
            let responseSerializer = DecodableResponseSerializer<[Activity]>(decoder: decoder)
            
            AF.request("https://www.strava.com/api/v3/athlete/activities", parameters: parameters, headers: headers)
                .validate(statusCode: 200..<300)
                .response(responseSerializer: responseSerializer, completionHandler: { response in
                    switch response.result {
                    case .success (let activities) :
                        self.bikes = self.getBikes()
//                        for activity in activities {
//                            if let bikeId = activity.gearId, let bikes = self.bikes {
//                                activity.bike = bikes.first(where: { $0.id == bikeId })
//                            }
//                        }
                        self.activities = activities
                        do {
                            // Save the changes to the managed object context
                            try self.managedObjectContext.save()
                            completion(.success(()))
                        } catch {
                            // Handle the error
                            print("Failed to save managed object context: \(error)")
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
        }
    }


    class AuthenticationSession: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            // Attempt to find a window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive && $0 is UIWindowScene }) as? UIWindowScene else {
                fatalError("Unable to find an active window scene")
            }

            // Attempt to find a window in the window scene
            guard let window = windowScene.windows.first else {
                fatalError("Unable to find a window in the active window scene")
            }

            return window
        }
    }
}
