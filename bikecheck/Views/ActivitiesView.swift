import SwiftUI

struct ActivitiesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var stravaService: StravaService
    @EnvironmentObject var viewModel: ActivitiesViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading activities...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if viewModel.activities.isEmpty {
                    Text("No activities found")
                } else {
                    List {
                        ForEach(viewModel.activities, id: \.self) { activity in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(activity.name)
                                    Spacer()
                                }
                                HStack {
                                    Text(viewModel.getFormattedDuration(for: activity))
                                    Spacer()
                                    Text(viewModel.getFormattedDistance(for: activity))
                                }
                                HStack {
                                    Text(viewModel.getBikeName(for: activity))
                                    Spacer()
                                    Text(viewModel.getFormattedDate(for: activity))
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
                viewModel.loadActivities()
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
