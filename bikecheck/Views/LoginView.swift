import SwiftUI

struct LoginView: View {
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        ZStack {
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
            
            if onboardingViewModel.showOnboarding {
                OnboardingOverlay(onboardingViewModel: onboardingViewModel)
            }
        }
        .onAppear {
            // Clear any test data when showing login screen
            onboardingViewModel.clearTestDataIfNeeded()
            
            if !hasCompletedOnboarding {
                onboardingViewModel.startOnboarding()
            }
        }
        .onChange(of: onboardingViewModel.showOnboarding) { newValue in
            if !newValue {
                hasCompletedOnboarding = true
            }
        }
        .onChange(of: onboardingViewModel.showTour) { showTour in
            if !showTour && hasCompletedOnboarding {
                // Tour has ended, ensure onboarding is marked complete
                hasCompletedOnboarding = true
            }
        }
        .onOpenURL { url in
            if url.scheme == "bikecheck" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let authCode = components?.queryItems?.first(where: { $0.name == "code" })?.value
                
                if let code = authCode {
                    stravaService.requestStravaTokens(with: code) { success in
                        if success {
                            DispatchQueue.main.async {
                                stravaService.isSignedIn = true
                                loginViewModel.isLoading = false
                            }
                        } else {
                            print("Error requesting tokens")
                            DispatchQueue.main.async {
                                loginViewModel.isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }
}