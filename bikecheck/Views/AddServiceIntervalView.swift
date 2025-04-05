import SwiftUI

struct AddServiceIntervalView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddServiceIntervalViewModel
    
    init(serviceInterval: ServiceInterval? = nil) {
        _viewModel = StateObject(wrappedValue: AddServiceIntervalViewModel(serviceInterval: serviceInterval))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Service Details")) {
                    Picker("Bike", selection: $viewModel.selectedBike) {
                        ForEach(viewModel.bikes, id: \.self) { bike in
                            Text(bike.name).tag(bike as Bike?)
                        }
                    }
                    
                    HStack {
                        Text("Part:")
                        Spacer()
                        TextField("Part", text: $viewModel.part)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Interval Time (hrs)")
                        Spacer()
                        TextField("Interval Time (hrs)", text: $viewModel.intervalTime)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if viewModel.serviceInterval != nil {
                        HStack {
                            Text("Time until service (hrs)")
                            Spacer()
                            Text(viewModel.timeUntilServiceText)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(
                                    (Double(viewModel.timeUntilServiceText) ?? 0) <= 0 ? .red : .primary
                                )
                        }
                    }
                    
                    Toggle(isOn: $viewModel.notify) {
                        Text("Notify")
                    }
                }
                
                if viewModel.serviceInterval != nil {
                    Section {
                        Button(action: {
                            viewModel.resetConfirmationDialog = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset Interval")
                            }
                            .foregroundColor(.blue)
                        }
                        .alert(isPresented: $viewModel.resetConfirmationDialog) {
                            Alert(
                                title: Text("Confirm Reset Interval"),
                                message: Text("Are you sure you want to reset this service interval?"),
                                primaryButton: .default(Text("Reset")) {
                                    viewModel.resetInterval()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button(action: {
                            viewModel.deleteConfirmationDialog = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .foregroundColor(.red)
                        }
                        .alert(isPresented: $viewModel.deleteConfirmationDialog) {
                            Alert(
                                title: Text("Confirm Removal"),
                                message: Text("Are you sure you want to remove this service interval?"),
                                primaryButton: .destructive(Text("Remove")) {
                                    viewModel.deleteInterval()
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
            }
            .navigationBarItems(
                leading: viewModel.serviceInterval == nil ? Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                } : nil,
                trailing: viewModel.serviceInterval == nil ? Button("Save") {
                    viewModel.saveServiceInterval()
                    presentationMode.wrappedValue.dismiss()
                } : nil
            )
            .onChange(of: presentationMode.wrappedValue.isPresented) { isPresented in
                if !isPresented && viewModel.serviceInterval != nil && viewModel.hasUnsavedChanges {
                    // Auto-save changes when navigating back
                    viewModel.saveServiceInterval()
                    viewModel.showUnsavedChangesAlert = true
                }
            }
            .alert(isPresented: $viewModel.showUnsavedChangesAlert) {
                Alert(
                    title: Text("Changes Saved"),
                    message: Text("Your changes have been saved."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                viewModel.loadBikes()
            }
        }
    }
}