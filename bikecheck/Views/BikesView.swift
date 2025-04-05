import SwiftUI

struct BikesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: BikesViewModel
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
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
                            NavigationLink(destination: BikeDetailView(bike: bike, selectedTab: $selectedTab)) {
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
