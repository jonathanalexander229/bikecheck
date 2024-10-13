//
//  BikesViewModel.swift
//  bikecheck
//
//  Created by clutchcoder on 1/31/24.
//
import SwiftUI
import CoreData

class BikesViewModel: ObservableObject {
    @Published var uiImage: UIImage?
    var stravaHelper: StravaHelper

    init(stravaHelper: StravaHelper) {
        self.stravaHelper = stravaHelper
    }

    func fetchAthleteAndActivities() {
        stravaHelper.getAthlete() { _ in }
        stravaHelper.fetchActivities() { _ in }

        if let urlString = stravaHelper.athlete?.profile, let url = URL(string: urlString) {
            loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            }
        }.resume()
    }
}
