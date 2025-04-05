import SwiftUI

struct LoginView: View {
    @EnvironmentObject var stravaHelper: StravaHelper
    @StateObject private var viewModel: LoginViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel(stravaHelper: StravaHelper.shared))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
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
                        viewModel.authenticate { _ in }
                    }) {
                        Text("Sign in with Strava")
                            .frame(width: 280, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    #if DEBUG
                    Button(action: {
                        viewModel.insertTestData()
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
        .onOpenURL { url in
            if url.scheme == "bikecheck" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let authCode = components?.queryItems?.first(where: { $0.name == "code" })?.value
                
                if let code = authCode {
                    stravaHelper.requestStravaTokens(with: code) { success in
                        if success {
                            DispatchQueue.main.async {
                                stravaHelper.isSignedIn = true
                                viewModel.isLoading = false
                            }
                        } else {
                            print("Error requesting tokens")
                            DispatchQueue.main.async {
                                viewModel.isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }
}