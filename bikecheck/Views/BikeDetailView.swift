import SwiftUI

struct BikeDetailView: View {
    @ObservedObject var bike: Bike
    @StateObject private var viewModel: BikeDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTab: Int
    @State private var showingIntervalsCreatedAlert = false
    
    init(bike: Bike, selectedTab: Binding<Int>) {
        self.bike = bike
        self._selectedTab = selectedTab
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
                        showingIntervalsCreatedAlert = true
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
                                presentationMode.wrappedValue.dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
        .navigationTitle("Bike Details")
        .alert(isPresented: $showingIntervalsCreatedAlert) {
            Alert(
                title: Text("Service Intervals Created"),
                message: Text("Default service intervals have been created for \(bike.name)"),
                dismissButton: .default(Text("OK")) {
                    // Switch to the Service Intervals tab (index 0)
                    selectedTab = 0
                    // Navigate back to the bikes list
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}