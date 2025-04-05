import SwiftUI

struct ServiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaHelper: StravaHelper
    @EnvironmentObject var viewModel: ServiceViewModel
    @State private var showingServiceIntervalView = false
    @Binding var uiImage: UIImage?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading service intervals...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if viewModel.serviceIntervals.isEmpty {
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
                        ForEach(viewModel.serviceIntervals, id: \.self) { serviceInterval in
                            NavigationLink(destination: AddServiceIntervalView(serviceInterval: serviceInterval)) {
                                VStack(alignment: .leading) {
                                    Text(serviceInterval.bike.name)
                                        .font(.subheadline)
                                    
                                    let timeUntilService = viewModel.calculateTimeUntilService(for: serviceInterval)
                                    
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
                viewModel.loadServiceIntervals()
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
    
    var addButton: some View {
        Button(action: {
            showingServiceIntervalView = true
        }) {
            Image(systemName: "plus")
        }
    }
}