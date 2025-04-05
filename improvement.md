I understand you'd like a complete implementation of the MVVM pattern for your BikeCheck app. I'll provide the full code for restructuring your existing app into an MVVM architecture.

Let's start with the directory structure and then go through each component systematically.

# Directory Structure

```
bikecheck/
├── App/
│   ├── bikecheckApp.swift
│   ├── AppDelegate.swift
│   ├── Info.plist
│
├── Models/
│   ├── Activity.swift
│   ├── Athlete.swift
│   ├── Bike.swift
│   ├── ServiceInterval.swift
│   └── TokenInfo.swift
│
├── ViewModels/
│   ├── BikesViewModel.swift
│   ├── ActivitiesViewModel.swift
│   ├── ServiceViewModel.swift
│   ├── BikeDetailViewModel.swift
│   ├── AddServiceIntervalViewModel.swift
│   └── LoginViewModel.swift
│
├── Views/
│   ├── Activities/
│   │   └── ActivitiesView.swift
│   │
│   ├── Authentication/
│   │   └── LoginView.swift
│   │
│   ├── Bikes/
│   │   ├── BikesView.swift
│   │   └── BikeDetailView.swift
│   │
│   ├── Service/
│   │   ├── ServiceView.swift
│   │   └── AddServiceIntervalView.swift
│   │
│   └── HomeView.swift
│
├── Services/
│   ├── StravaService.swift
│   ├── NotificationService.swift
│   └── DataService.swift
│
├── Persistence/
│   └── PersistenceController.swift
│
└── Resources/
    ├── Assets.xcassets/
    └── bikecheck.xcdatamodeld/
```

# Services

## StravaService.swift
```swift
import Foundation
import CoreData
import Alamofire
import Combine

class StravaService: ObservableObject {
    static let shared = StravaService()
    
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
        let appOAuthUrlStravaScheme = URL(string: "https://www.strava.com/oauth/mobile/authorize?client_id=\(clientId)&redirect_uri=\(urlScheme)%3A%2F%2F\(callbackUrl)&response_type=\(responseType)&approval_prompt=auto&scope=\(scope)")!
        
        let callback: ASWebAuthenticationSession.CompletionHandler = { url, error in
            if let error = error {
                if let authError = error as? ASWebAuthenticationSessionError, 
                   authError.code == .canceledLogin {
                    print("User canceled the login process.")
                } else {
                    print("Authentication error: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    completion(false)
                }
            } else if let url = url, let code = self.getCode(from: url) {
                self.requestStravaTokens(with: code) { success in
                    DispatchQueue.main.async {
                        self.isSignedIn = success
                        if success {
                            self.fetchAthleteData()
                        }
                        completion(success)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
        
        if UIApplication.shared.canOpenURL(appOAuthUrlStravaScheme) {
            UIApplication.shared.open(appOAuthUrlStravaScheme, options: [:])
        } else {
            let contextProvider = AuthenticationSession()
            authSession = ASWebAuthenticationSession(url: appOAuthUrlStravaScheme, callbackURLScheme: "bikecheck", completionHandler: callback)
            authSession?.presentationContextProvider = contextProvider
            authSession?.start()
        }
    }
    
    private func getCode(from url: URL?) -> String? {
        guard let url = url?.absoluteString else { return nil }
        
        let urlComponents: URLComponents? = URLComponents(string: url)
        return urlComponents?.queryItems?.filter { $0.name == "code" }.first?.value
    }
    
    func requestStravaTokens(with code: String, completion: @escaping (Bool) -> Void) {
        let parameters: [String: Any] = [
            "client_id": clientId, 
            "client_secret": clientSecret, 
            "code": code, 
            "grant_type": "authorization_code"
        ]
        
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
    
    func getAthlete(completion: @escaping (Result<Void, Error>) -> Void) {
        getAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get access token"])))
                return
            }
            
            if self.tokenInfo?.expiresAt == 9999999999 {
                completion(.success(()))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = self.managedObjectContext
            
            let responseSerializer = DecodableResponseSerializer<Athlete>(decoder: decoder)
            
            AF.request("https://www.strava.com/api/v3/athlete", headers: ["Authorization": "Bearer \(accessToken)"]).response(responseSerializer: responseSerializer) { response in
                switch response.result {
                case .success(let athlete):
                    self.athlete = athlete
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
    
    func fetchActivities(completion: @escaping (Result<Void, Error>) -> Void) {
        getAccessToken { accessToken in
            guard let accessToken = accessToken else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get access token"])))
                return
            }
            
            if self.tokenInfo?.expiresAt == 9999999999 {
                print("Demo Mode")
                completion(.success(()))
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
            
            AF.request("https://www.strava.com/api/v3/athlete/activities", parameters: parameters, headers: headers)
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
    
    func checkServiceIntervals() {
        let serviceIntervals = fetchServiceIntervals()
        
        serviceIntervals.forEach { interval in
            let timeUntilService = calculateTimeUntilService(for: interval)
            if timeUntilService <= 0 && interval.notify {
                NotificationService.shared.sendNotification(for: interval)
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
    
    func insertTestData() {
        // Implementation remains the same
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
```

## NotificationService.swift
```swift
import UserNotifications
import BackgroundTasks

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion(granted, error)
        }
    }
    
    func sendNotification(for interval: ServiceInterval) {
        if interval.notify {
            print("Sending notification")
            let content = UNMutableNotificationContent()
            content.title = "\(interval.bike.name) Service Reminder"
            content.body = "It's time to service your \(interval.part)."
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            
            center.add(request) { (error) in
                if let error = error {
                    print("Error adding notification request: \(error.localizedDescription)")
                } else {
                    print("Notification request added successfully")
                }
            }
        }
    }
    
    func scheduleBackgroundTask() {
        print("scheduling serviceInt Notification background task")
        let request = BGAppRefreshTaskRequest(identifier: "checkServiceInterval")
        request.earliestBeginDate = Calendar.current.date(byAdding: .minute, value: 6, to: Date())
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification while in the foreground")
        completionHandler([.banner, .sound])
    }
}
```

## DataService.swift
```swift
import Foundation
import CoreData

class DataService {
    static let shared = DataService()
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchBikes() -> [Bike] {
        let fetchRequest: NSFetchRequest<Bike> = Bike.fetchRequest() as! NSFetchRequest<Bike>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Bike.name, ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch bikes: \(error)")
            return []
        }
    }
    
    func fetchActivities() -> [Activity] {
        let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest() as! NSFetchRequest<Activity>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Activity.startDate, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "type == %@", "Ride")
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch activities: \(error)")
            return []
        }
    }
    
    func fetchServiceIntervals() -> [ServiceInterval] {
        let fetchRequest: NSFetchRequest<ServiceInterval> = ServiceInterval.fetchRequest() as! NSFetchRequest<ServiceInterval>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceInterval.startTime, ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch service intervals: \(error)")
            return []
        }
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func createDefaultServiceIntervals(for bike: Bike) {
        let newServInt1 = ServiceInterval(context: context)
        let newServInt2 = ServiceInterval(context: context)
        let newServInt3 = ServiceInterval(context: context)
        
        newServInt2.intervalTime = 5
        newServInt2.startTime = 0
        newServInt2.bike = bike
        newServInt2.part = "chain"
        newServInt2.notify = true
        
        newServInt3.intervalTime = 10
        newServInt3.startTime = 0
        newServInt3.bike = bike
        newServInt3.part = "Fork Lowers"
        newServInt3.notify = true
        
        newServInt1.intervalTime = 15
        newServInt1.startTime = 0
        newServInt1.bike = bike
        newServInt1.part = "Shock"
        newServInt1.notify = true
        
        saveContext()
    }
    
    func deleteBike(_ bike: Bike) {
        context.delete(bike)
        saveContext()
    }
}
```

# ViewModels

## BikesViewModel.swift
```swift
import Foundation
import Combine
import SwiftUI

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
```

## ActivitiesViewModel.swift
```swift
import Foundation
import Combine

class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        loadActivities()
    }
    
    func loadActivities() {
        isLoading = true
        activities = dataService.fetchActivities()
        isLoading = false
    }
    
    func getBikeName(for activity: Activity) -> String {
        let bikes = dataService.fetchBikes()
        return bikes.first(where: { $0.id == activity.gearId })?.name ?? "none"
    }
    
    func getFormattedDate(for activity: Activity) -> String {
        return DateFormatter.localizedString(from: activity.startDate, dateStyle: .medium, timeStyle: .none)
    }
    
    func getFormattedDuration(for activity: Activity) -> String {
        return String(format: "%.2f hours", Double(activity.movingTime) / 3600)
    }
    
    func getFormattedDistance(for activity: Activity) -> String {
        return String(format: "%.2f km", activity.distance / 1000)
    }
}
```

## ServiceViewModel.swift
```swift
import Foundation
import Combine

class ServiceViewModel: ObservableObject {
    @Published var serviceIntervals: [ServiceInterval] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataService = DataService.shared
    private let stravaService = StravaService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        loadServiceIntervals()
    }
    
    func loadServiceIntervals() {
        isLoading = true
        serviceIntervals = dataService.fetchServiceIntervals()
        isLoading = false
    }
    
    func calculateTimeUntilService(for serviceInterval: ServiceInterval) -> Double {
        return stravaService.calculateTimeUntilService(for: serviceInterval)
    }
    
    func getTimeUntilServiceText(for serviceInterval: ServiceInterval) -> String {
        let timeUntilService = calculateTimeUntilService(for: serviceInterval)
        return String(format: "%.2f", timeUntilService)
    }
    
    func deleteInterval(serviceInterval: ServiceInterval) {
        context.delete(serviceInterval)
        dataService.saveContext()
        loadServiceIntervals()
    }
    
    func resetInterval(serviceInterval: ServiceInterval) {
        serviceInterval.startTime = serviceInterval.bike.rideTime(context: context)
        dataService.saveContext()
    }
}
```

## BikeDetailViewModel.swift
```swift
import Foundation
import Combine

class BikeDetailViewModel: ObservableObject {
    @Published var bike: Bike
    @Published var showingConfirmationDialog = false
    
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
    }
}
```

## AddServiceIntervalViewModel.swift
```swift
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
    
    private let dataService = DataService.shared
    private let context = PersistenceController.shared.container.viewContext
    
    var serviceInterval: ServiceInterval?
    
    init(serviceInterval: ServiceInterval? = nil) {
        self.serviceInterval = serviceInterval
        loadBikes()
        if let serviceInterval = serviceInterval {
            loadServiceIntervalData(serviceInterval)
        }
    }
    
    func loadBikes() {
        bikes = dataService.fetchBikes()
        if selectedBike == nil && !bikes.isEmpty {
            selectedBike = bikes.first
        }
    }
    
    private func loadServiceIntervalData(_ serviceInterval: ServiceInterval) {
        part = serviceInterval.part
        startTime = serviceInterval.startTime
        intervalTime = String(serviceInterval.intervalTime)
        notify = serviceInterval.notify
        selectedBike = serviceInterval.bike
        updateTimeUntilService()
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
        
        dataService.saveContext()
    }
    
    private func createNewInterval() {
        guard let selectedBike = selectedBike else { return }
        
        let newInterval = ServiceInterval(context: context)
        newInterval.part = part
        newInterval.intervalTime = Double(intervalTime) ?? 0
        newInterval.notify = notify
        newInterval.startTime = selectedBike.rideTime(context: context)
        newInterval.bike = selectedBike
        
        dataService.saveContext()
    }
    
    func resetInterval() {
        guard let serviceInterval = serviceInterval, let selectedBike = selectedBike else { return }
        
        serviceInterval.startTime = selectedBike.rideTime(context: context)
        timeUntilServiceText = String(format: "%.2f", serviceInterval.intervalTime)
        
        dataService.saveContext()
    }
    
    func deleteInterval() {
        guard let serviceInterval = serviceInterval else { return }
        
        context.delete(serviceInterval)
        dataService.saveContext()
    }
}
```

## LoginViewModel.swift
```swift
import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    
    private let stravaService = StravaService.shared
    
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
}
```

# Views

## bikecheckApp.swift
```swift
import SwiftUI
import BackgroundTasks

@main
struct bikecheckApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var stravaService = StravaService.shared
    
    // ViewModels
    @StateObject var bikesViewModel = BikesViewModel()
    @StateObject var activitiesViewModel = ActivitiesViewModel()
    @StateObject var serviceViewModel = ServiceViewModel()
    @StateObject var loginViewModel = LoginViewModel()
    
    let notificationDelegate = NotificationDelegate()
    
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        setupBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if stravaService.isSignedIn ?? false {
                    HomeView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaService)
                        .environmentObject(bikesViewModel)
                        .environmentObject(activitiesViewModel)
                        .environmentObject(serviceViewModel)
                } else {
                    LoginView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(stravaService)
                        .environmentObject(loginViewModel)
                }
            }
        }
        .backgroundTask(.appRefresh("com.bikecheck.checkServiceInterval")) { task in
            stravaService.checkServiceIntervals()
        }
        .backgroundTask(.appRefresh("com.bikecheck.fetchActivities")) { task in
            stravaService.fetchActivities { _ in }
        }
    }
    
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.fetchActivities", using: nil) { task in
            handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bikecheck.checkServiceInterval", using: nil) { task in
            handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        if task.identifier == "com.bikecheck.fetchActivities" {
            stravaService.fetchActivities { result in
                switch result {
                case .success:
                    task.setTaskCompleted(success: true)
                case .failure:
                    task.setTaskCompleted(success: false)
                }
            }
        } else if task.identifier == "com.bikecheck.checkServiceInterval" {
            stravaService.checkServiceIntervals()
            task.setTaskCompleted(success: true)
        }
    }
}
```

## HomeView.swift
```swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var bikesViewModel: BikesViewModel
    @EnvironmentObject var activitiesViewModel: ActivitiesViewModel
    @EnvironmentObject var serviceViewModel: ServiceViewModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ServiceView()
                .tabItem {
                    VStack {
                        Image(systemName: "timer")
                        Text("Service Intervals")
                    }
                }
                .tag(0)
            
            BikesView()
                .tabItem {
                    VStack {
                        Image(systemName: "bicycle")
                        Text("Bikes")
                    }
                }
                .tag(1)
            
            ActivitiesView()
                .tabItem {
                    VStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("Activities")
                    }
                }
                .tag(2)
        }
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        NotificationService.shared.requestAuthorization { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if !granted {
                print("Notification permissions not granted")
            } else {
                print("Notification permissions granted")
            }
        }
    }
}
```

## BikesView.swift
```swift
import SwiftUI

struct BikesView: View {
    @EnvironmentObject var bikesViewModel: BikesViewModel
    @EnvironmentObject var stravaService: StravaService
    
    var body: some View {
        NavigationView {
            Group {
                if bikesViewModel.isLoading {
                    ProgressView("Loading bikes...")
                } else if let error = bikesViewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if bikesViewModel.bikes.isEmpty {
                    Text("No bikes found")
                } else {
                    List {
                        ForEach(Array(bikesViewModel.bikes), id: \.self) { bike in
                            NavigationLink(destination: BikeDetailView(bike: bike)) {
                                HStack {
                                    Text(bike.name)
                                    Spacer()
                                    Text(bikesViewModel.getTotalRideTime(for: bike))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bikes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: profileImage)
            .onAppear {
                bikesViewModel.loadBikes()
            }
        }
    }
    
    var profileImage: some View {
        Group {
            if let image = stravaService.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
            }
        }
    }
}
```

## BikeDetailView.swift
```swift
import SwiftUI

struct BikeDetailView: View {
    @ObservedObject var bike: Bike
    @StateObject private var viewModel: BikeDetailViewModel
    
    init(bike: Bike) {
        self.bike = bike
        _viewModel = StateObject(wrappedValue: BikeDetailViewModel(bike: bike))
    }
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Bike Info")) {
                    Text(bike.name)
                    Text("\(viewModel.getMileage()) miles")
                    Text("\(viewModel.getTotalRideTime()) hrs")
                    Text("\(viewModel.getActivityCount()) activities")
                }
                
                Section {
                    Button(action: {
                        viewModel.createDefaultServiceIntervals()
                    }) {
                        Text("Create Default Service Intervals")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        viewModel.showingConfirmationDialog = true
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $viewModel.showingConfirmationDialog) {
                        Alert(
                            title: Text("Confirm Deletion"),
                            message: Text("Are you sure you want to delete this bike? (if its a strava bike, it will be re-imported on the next sync)"),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.deleteBike()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
        .navigationTitle("Bike Details")
    }
}
```

## ActivitiesView.swift
```swift
import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var activitiesViewModel: ActivitiesViewModel
    @EnvironmentObject var stravaService: StravaService
    
    var body: some View {
        NavigationView {
            Group {
                if activitiesViewModel.isLoading {
                    ProgressView("Loading activities...")
                } else if let error = activitiesViewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if activitiesViewModel.activities.isEmpty {
                    Text("No activities found")
                } else {
                    List {
                        ForEach(Array(activitiesViewModel.activities), id: \.self) { activity in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(activity.name)
                                    Spacer()
                                }
                                HStack {
                                    Text(activitiesViewModel.getFormattedDuration(for: activity))
                                    Spacer()
                                    Text(activitiesViewModel.getFormattedDistance(for: activity))
                                }
                                HStack {
                                    Text(activitiesViewModel.getBikeName(for: activity))
                                    Spacer()
                                    Text(activitiesViewModel.getFormattedDate(for: activity))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: profileImage)
            .onAppear {
                activitiesViewModel.loadActivities()
            }
        }
    }
    
    var profileImage: some View {
        Group {
            if let image = stravaService.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
            }
        }
    }
}
```

## ServiceView.swift
```swift
import SwiftUI

struct ServiceView: View {
    @EnvironmentObject var serviceViewModel: ServiceViewModel
    @EnvironmentObject var stravaService: StravaService
    @State private var showingServiceIntervalView = false
    
    var body: some View {
        NavigationView {
            Group {
                if serviceViewModel.isLoading {
                    ProgressView("Loading service intervals...")
                } else if let error = serviceViewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if serviceViewModel.serviceIntervals.isEmpty {
                    VStack {
                        Text("No service intervals found")
                        
                        Button(action: {
                            showingServiceIntervalView = true
                        }) {
                            Text("Add Service Interval")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                } else {
                    List {
                        ForEach(Array(serviceViewModel.serviceIntervals), id: \.self) { serviceInterval in
                            NavigationLink(destination: AddServiceIntervalView(serviceInterval: serviceInterval)) {
                                VStack(alignment: .leading) {
                                    Text(serviceInterval.bike.name)
                                        .font(.subheadline)
                                    
                                    let timeUntilService = serviceViewModel.calculateTimeUntilService(for: serviceInterval)
                                    
                                    HStack {
                                        Text("service \(serviceInterval.part.lowercased())")
                                            .font(.subheadline)
                                            .italic()
                                        Spacer()
                                        Text("in \(String(format: "%.2f", timeUntilService)) hrs")
                                            .foregroundColor(timeUntilService <= 0 ? .red : .primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Service Intervals")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: profileImage,
                trailing: addButton
            )
            .sheet(isPresented: $showingServiceIntervalView) {
                AddServiceIntervalView()
            }
            .onAppear {
                serviceViewModel.loadServiceIntervals()
            }
        }
    }
    
    var profileImage: some View {
        Group {
            if let image = stravaService.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
            }
        }
    }
    
    var addButton: some View {
        Button(action: {
            showingServiceIntervalView = true
        }) {
            Image(systemName: "plus")
        }
    }
}
```

## AddServiceIntervalView.swift
```swift
import SwiftUI

struct AddServiceIntervalView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddServiceIntervalViewModel
    
    init(serviceInterval: ServiceInterval? = nil) {
        _viewModel = StateObject(wrappedValue: AddServiceIntervalViewModel(serviceInterval: serviceInterval))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Service Details")) {
                    Picker("Bike", selection: $viewModel.selectedBike) {
                        ForEach(viewModel.bikes, id: \.self) { bike in
                            Text(bike.name).tag(bike as Bike?)
                        }
                    }
                    
                    HStack {
                        Text("Part:")
                        Spacer()
                        TextField("Part", text: $viewModel.part)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Interval Time (hrs)")
                        Spacer()
                        TextField("Interval Time (hrs)", text: $viewModel.intervalTime)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if viewModel.serviceInterval != nil {
                        HStack {
                            Text("Time until service (hrs)")
                            Spacer()
                            Text(viewModel.timeUntilServiceText)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(
                                    (Double(viewModel.timeUntilServiceText) ?? 0) <= 0 ? .red : .primary
                                )
                        }
                    }
                    
                    Toggle(isOn: $viewModel.notify) {
                        Text("Notify")
                    }
                }
                
                if viewModel.serviceInterval != nil {
                    Section {
                        Button(action: {
                            viewModel.resetConfirmationDialog = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset Interval")
                            }
                            .foregroundColor(.blue)
                        }
                        .alert(isPresented: $viewModel.resetConfirmationDialog) {
                            Alert(
                                title: Text("Confirm Reset Interval"),
                                message: Text("Are you sure you want to reset this service interval?"),
                                primaryButton: .default(Text("Reset")) {
                                    viewModel.resetInterval()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button(action: {
                            viewModel.deleteConfirmationDialog = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .foregroundColor(.red)
                        }
                        .alert(isPresented: $viewModel.deleteConfirmationDialog) {
                            Alert(
                                title: Text("Confirm Removal"),
                                message: Text("Are you sure you want to remove this service interval?"),
                                primaryButton: .destructive(Text("Remove")) {
                                    viewModel.deleteInterval()
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
            }
            .navigationTitle(viewModel.serviceInterval == nil ? "Add Service Interval" : "Edit Service Interval")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    viewModel.saveServiceInterval()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                viewModel.loadBikes()
            }
        }
    }
}
```

## LoginView.swift
```swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        Group {
            if loginViewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 20) {
                    Text("BikeCheck")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Image("BikeCheckLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .cornerRadius(30)
                        .shadow(color: .gray, radius: 1, x: 5, y: 5)
                    
                    Button(action: {
                        loginViewModel.authenticate { _ in }
                    }) {
                        Text("Sign in with Strava")
                            .frame(width: 280, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    #if DEBUG
                    Button(action: {
                        loginViewModel.insertTestData()
                    }) {
                        Text("Insert Test Data")
                            .frame(width: 280, height: 60)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    #endif
                }
            }
        }
    }
}
```

# Implementation Steps

1. **Create the directory structure in Xcode**:
   - Right-click on your project in the Project Navigator
   - Select "New Group" for each top-level folder (App, Models, ViewModels, etc.)
   - Create nested groups for subfolders

2. **Move existing files to their appropriate locations**:
   - Move your model files to the Models folder
   - Move your views to the Views folder and its subfolders

3. **Create new service files**:
   - Create StravaService.swift (based on your existing StravaHelper)
   - Create NotificationService.swift (based on your existing NotificationManager)
   - Create DataService.swift (new)

4. **Create ViewModels**:
   - Create ViewModels for each view

5. **Update Views**:
   - Update views to use the new ViewModels

6. **Update the App Entry Point**:
   - Update bikecheckApp.swift to use the new services and ViewModels

This MVVM architecture:
- Separates your business logic (in ViewModels) from UI code (in Views)
- Makes data flow more predictable through published properties
- Improves testability since ViewModels can be tested independently
- Organizes your code by responsibility
- Makes it easier to add new features or modify existing ones

It maintains the use of singletons where they make sense while introducing proper separation of concerns. You can implement these changes incrementally, focusing on one view at a time to minimize disruption to your app's functionality.