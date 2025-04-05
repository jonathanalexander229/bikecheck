import SwiftUI

struct BikesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaHelper: StravaHelper
    @StateObject private var viewModel = BikesViewModel()
    @Binding var uiImage: UIImage?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading bikes...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if viewModel.bikes.isEmpty {
                    Text("No bikes found")
                } else {
                    List {
                        ForEach(viewModel.bikes, id: \.self) { bike in
                            NavigationLink(destination: BikeDetailView(bike: bike)) {
                                HStack {
                                    Text(bike.name)
                                    Spacer()
                                    Text(viewModel.getTotalRideTime(for: bike))
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
                viewModel.loadBikes()
            }
        }
    }
    
    var profileImage: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                EmptyView()
            }
        }
    }
}