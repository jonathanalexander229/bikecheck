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