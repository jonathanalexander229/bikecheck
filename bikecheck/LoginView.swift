//
//  LoginView.swift
//  bikeCheck
//
//  Created by clutchcoder on 12/24/23.
//

import SwiftUI
//import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var stravaAuth: StravaHelper

    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 20) { // Add VStack here
                    Text("BikeCheck") // App title
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Image("BikeCheckLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .cornerRadius(30) // Makes the image circular
                        .shadow(color: .gray, radius: 1, x: 5, y: 5) // Adds a shadow for a 3D effect

                    Button(action: {
                        isLoading = true
                        stravaAuth.authenticate { success in
                            isLoading = false
                        }
                    }) {
                        Text("Sign in with Strava")
                            .frame(width: 280, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .onOpenURL { url in
            // Handle the URL
            if url.scheme == "bikecheck" {
                // Extract the auth code from the URL
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let authCode = components?.queryItems?.first(where: { $0.name == "code" })?.value
                print(url)
                // Use the auth code to request an access token
                stravaAuth.requestStravaTokens(with: authCode!) { success in
                    if success {
                        // The `TokenInfo` was successfully stored in `UserDefaults`.
                        DispatchQueue.main.async {
                            stravaAuth.isSignedIn = true
                            isLoading = false
                        }
                    } else {
                        print("error")// The `TokenInfo` could not be stored in `UserDefaults`.
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
