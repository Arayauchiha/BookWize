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
    @State private var isEditing = false
    @State private var showingUpdateMenu = false

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
                editedFine = settings.perDayFine != nil ? String(settings.perDayFine!) : ""
                editedMembership = settings.membership != nil ? String(settings.membership!) : ""
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
                editedFine = defaultSettings.perDayFine != nil ? String(defaultSettings.perDayFine!) : ""
                editedMembership = defaultSettings.membership != nil ? String(defaultSettings.membership!) : ""
            }
            isLoading = false
        } catch {
            if error.localizedDescription.contains("permission denied") {
                errorMessage = "Access denied: Admins only"
            } else {
                errorMessage = "Failed to fetch or create settings: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func updateSettings() async {
        guard let fineSetId = fineSetId else {
            errorMessage = "Missing record ID. Please try again."
            return
        }

        guard let newFine = Double(editedFine) else {
            errorMessage = "Invalid fine amount. Please enter a valid number."
            return
        }

        guard let newMembership = Double(editedMembership) else {
            errorMessage = "Invalid membership amount. Please enter a valid number."
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
            isEditing = false
            showingUpdateMenu = false
        } catch {
            if error.localizedDescription.contains("permission denied") {
                errorMessage = "Access denied: Admins only"
            } else {
                errorMessage = "Failed to update settings: \(error.localizedDescription)"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.customBackground.ignoresSafeArea() // Apply custom background color
                
                if isLoading {
                    ProgressView()
                        .tint(Color.customText) // Use custom text color for the progress view
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red) // Keep error text red for visibility
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Per Day Fine")
                                    .font(.headline)
                                    .foregroundColor(Color.customText) // Apply custom text color
                                Spacer()
                                if isEditing {
                                    TextField("$0.00", text: $editedFine)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.headline)
                                        .foregroundColor(Color.customText) // Apply custom text color
                                        .padding(8)
                                        .background(Color.customInputBackground) // Apply input background color
                                        .cornerRadius(5)
                                } else {
                                    Text(perDayFine != nil ? String(format: "$%.2f", perDayFine!) : "$0.00")
                                        .font(.headline)
                                        .foregroundColor(Color.customText) // Apply custom text color
                                }
                            }
                            .padding(.horizontal)
                            
                            Divider()
                                .background(Color.customText.opacity(0.2)) // Subtle divider color
                            
                            HStack {
                                Text("Membership Fee")
                                    .font(.headline)
                                    .foregroundColor(Color.customText) // Apply custom text color
                                Spacer()
                                if isEditing {
                                    TextField("$0.00", text: $editedMembership)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.headline)
                                        .foregroundColor(Color.customText) // Apply custom text color
                                        .padding(8)
                                        .background(Color.customInputBackground) // Apply input background color
                                        .cornerRadius(5)
                                } else {
                                    Text(membership != nil ? String(format: "$%.2f", membership!) : "$0.00")
                                        .font(.headline)
                                        .foregroundColor(Color.customText) // Apply custom text color
                                }
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.customCardBackground) // Apply card background color
                        .cornerRadius(10)
                        .shadow(color: Color.customText.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding()
                        
                        Spacer()
                    }
                }
            }
            //.navigationTitle("Fines & Fees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Update") {
                            isEditing = true
                            showingUpdateMenu = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color.customText.opacity(Color.secondaryIconOpacity)) // Apply custom text color with opacity
                    }
                }
            }
        }
        .task {
            await fetchSettings()
        }
        .sheet(isPresented: $showingUpdateMenu) {
            VStack {
                if isEditing {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Per Day Fine")
                                .foregroundColor(Color.customText) // Apply custom text color
                            Spacer()
                            TextField("$0.00", text: $editedFine)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.customText) // Apply custom text color
                                .padding(8)
                                .background(Color.customInputBackground) // Apply input background color
                                .cornerRadius(5)
                        }
                        .padding()
                        
                        Divider()
                            .background(Color.customText.opacity(0.2)) // Subtle divider color
                        
                        HStack {
                            Text("Membership Fee")
                                .foregroundColor(Color.customText) // Apply custom text color
                            Spacer()
                            TextField("$0.00", text: $editedMembership)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.customText) // Apply custom text color
                                .padding(8)
                                .background(Color.customInputBackground) // Apply input background color
                                .cornerRadius(5)
                        }
                        .padding()
                        
                        Button("Save") {
                            Task {
                                await updateSettings()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.customButton) // Apply custom button color
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.adminColor, lineWidth: 1) // Add admin color border for accent
                        )
                    }
                    .background(Color.customCardBackground) // Apply card background color
                    .cornerRadius(15)
                    .padding()
                }
            }
            .background(Color.customBackground) // Apply custom background color to the sheet
            .presentationDetents([.medium])
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
