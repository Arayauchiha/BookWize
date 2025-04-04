import SwiftUI
import Supabase

struct FineAndMembershipManagement: View {
    @State private var perDayFine: Double? = nil
    @State private var membership: Double? = nil
    @State private var fineSetId: String? = nil
    @State private var editedFine: String = ""
    @State private var editedMembership: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showingUpdateSheet = false
    @State private var showingErrorAlert = false
    
    private func fetchSettings() async {
        do {
            let response: [FineAndMembership] = try await SupabaseManager.shared.client
                .from("FineAndMembershipSet")
                .select("FineSet_id, PerDayFine, Membership")
                .limit(1)
                .execute()
                .value

            if let settings = response.first {
                perDayFine = settings.perDayFine
                membership = settings.membership
                fineSetId = settings.fineSetId
                editedFine = settings.perDayFine != nil ? String(format: "%.2f", settings.perDayFine!) : ""
                editedMembership = settings.membership != nil ? String(format: "%.2f", settings.membership!) : ""
                HapticManager.success()
            } else {
                let defaultSettings: FineAndMembership = try await SupabaseManager.shared.client
                    .from("FineAndMembershipSet")
                    .insert([
                        "PerDayFine": 6.0,
                        "Membership": 20.0
                    ])
                    .select("FineSet_id, PerDayFine, Membership")
                    .single()
                    .execute()
                    .value

                perDayFine = defaultSettings.perDayFine
                membership = defaultSettings.membership
                fineSetId = defaultSettings.fineSetId
                editedFine = defaultSettings.perDayFine != nil ? String(format: "%.2f", defaultSettings.perDayFine!) : ""
                editedMembership = defaultSettings.membership != nil ? String(format: "%.2f", defaultSettings.membership!) : ""
                HapticManager.success()
            }
            isLoading = false
        } catch {
            if error.localizedDescription.contains("permission denied") {
                errorMessage = "Access denied: Admins only"
            } else {
                errorMessage = "Failed to fetch or create settings: \(error.localizedDescription)"
            }
            isLoading = false
            showingErrorAlert = true
            HapticManager.error()
        }
    }

    private func updateSettings() async {
        guard let fineSetId = fineSetId else {
            errorMessage = "Missing record ID. Please try again."
            showingErrorAlert = true
            HapticManager.error()
            return
        }

        guard let newFine = Double(editedFine) else {
            errorMessage = "Invalid fine amount. Please enter a valid number."
            showingErrorAlert = true
            HapticManager.error()
            return
        }

        guard let newMembership = Double(editedMembership) else {
            errorMessage = "Invalid membership amount. Please enter a valid number."
            showingErrorAlert = true
            HapticManager.error()
            return
        }

        do {
            try await SupabaseManager.shared.client
                .from("FineAndMembershipSet")
                .update([
                    "PerDayFine": newFine,
                    "Membership": newMembership
                ])
                .eq("FineSet_id", value: fineSetId)
                .execute()

            perDayFine = newFine
            membership = newMembership
            showingUpdateSheet = false
            HapticManager.success()
        } catch {
            if error.localizedDescription.contains("permission denied") {
                errorMessage = "Access denied: Admins only"
            } else {
                errorMessage = "Failed to update settings: \(error.localizedDescription)"
            }
            showingErrorAlert = true
            HapticManager.error()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            } else {
                // Fines & Fees content
                VStack(spacing: 0) {
                    // Per Day Fine
                    HStack {
                        Text("Per Day Fine")
                            .font(.body)
                        
                        Spacer()
                        
                        Text(perDayFine != nil ? String(format: "$%.2f", perDayFine!) : "$0.00")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    
                    Divider()
                        .padding(.leading)
                        .background(Color(.secondarySystemGroupedBackground))
                    
                    // Membership Fee
                    HStack {
                        Text("Membership Fee")
                            .font(.body)
                        
                        Spacer()
                        
                        Text(membership != nil ? String(format: "$%.2f", membership!) : "$0.00")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .cornerRadius(10)
                .padding()
                
                Spacer()
                
                // Edit button at the bottom
                Button(action: {
                    HapticManager.mediumImpact()
                    showingUpdateSheet = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Fee Settings")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.librarianColor)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingUpdateSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Edit Fee Settings")) {
                        HStack {
                            Text("Per Day Fine")
                            Spacer()
                            TextField("0.00", text: $editedFine)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: editedFine) { _, newValue in
                                    if let _ = Double(newValue) {
                                        HapticManager.lightImpact()
                                    }
                                }
                        }
                        
                        HStack {
                            Text("Membership Fee")
                            Spacer()
                            TextField("0.00", text: $editedMembership)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: editedMembership) { _, newValue in
                                    if let _ = Double(newValue) {
                                        HapticManager.lightImpact()
                                    }
                                }
                        }
                    }
                }
                .navigationTitle("Update Fees")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            HapticManager.lightImpact()
                            showingUpdateSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            HapticManager.mediumImpact()
                            Task {
                                await updateSettings()
                            }
                        }
                        .bold()
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            await fetchSettings()
        }
        .alert(isPresented: $showingErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    HapticManager.lightImpact()
                }
            )
        }
    }
}

struct FineAndMembership: Decodable {
    let fineSetId: String
    let perDayFine: Double?
    let membership: Double?

    enum CodingKeys: String, CodingKey {
        case fineSetId = "FineSet_id"
        case perDayFine = "PerDayFine"
        case membership = "Membership"
    }
}

#Preview {
    FineAndMembershipManagement()
}
