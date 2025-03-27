//
//  FineAndMembershipManagement.swift
//  BookWize
//
//  Created by Abcom on 27/03/25.
//


//
//import SwiftUI
//import Supabase
//
//struct FineAndMembershipManagement: View {
//    @State private var perDayFine: Double? = nil
//    @State private var membership: Double? = nil
//    @State private var fineSetId: String? = nil
//    @State private var isEditingFine = false
//    @State private var isEditingMembership = false
//    @State private var editedFine: String = ""
//    @State private var editedMembership: String = ""
//    @State private var isLoading = true
//    @State private var errorMessage: String? = nil
//
//    private func fetchSettings() async {
//        do {
//            let response: [FineAndMembership] = try await SupabaseManager.shared.client
//                .from("FineAndMembershipSet")
//                .select("FineSet_id, PerDayFine, Membership")
//                .limit(1)
//                .execute()
//                .value
//
//            if let settings = response.first {
//                perDayFine = settings.perDayFine
//                membership = settings.membership
//                fineSetId = settings.fineSetId
//                editedFine = settings.perDayFine != nil ? String(settings.perDayFine!) : ""
//                editedMembership = settings.membership != nil ? String(settings.membership!) : ""
//            } else {
//                let defaultSettings: FineAndMembership = try await SupabaseManager.shared.client
//                    .from("FineAndMembershipSet")
//                    .insert([
//                        "PerDayFine": 1.0,
//                        "Membership": 10.0
//                    ])
//                    .select("FineSet_id, PerDayFine, Membership")
//                    .single()
//                    .execute()
//                    .value
//
//                perDayFine = defaultSettings.perDayFine
//                membership = defaultSettings.membership
//                fineSetId = defaultSettings.fineSetId
//                editedFine = defaultSettings.perDayFine != nil ? String(defaultSettings.perDayFine!) : ""
//                editedMembership = defaultSettings.membership != nil ? String(defaultSettings.membership!) : ""
//            }
//            isLoading = false
//        } catch {
//            // Check if the error is due to RLS (permission denied)
//            if error.localizedDescription.contains("permission denied") {
//                errorMessage = "Access denied: Admins only"
//            } else {
//                errorMessage = "Failed to fetch or create settings: \(error.localizedDescription)"
//            }
//            isLoading = false
//        }
//    }
//
//    private func updateSettings() async {
//        guard let fineSetId = fineSetId else {
//            errorMessage = "Missing record ID. Please try again."
//            return
//        }
//
//        guard let newFine = Double(editedFine) else {
//            errorMessage = "Invalid fine amount. Please enter a valid number."
//            return
//        }
//
//        guard let newMembership = Double(editedMembership) else {
//            errorMessage = "Invalid membership amount. Please enter a valid number."
//            return
//        }
//
//        do {
//            try await SupabaseManager.shared.client
//                .from("FineAndMembershipSet")
//                .update([
//                    "PerDayFine": newFine,
//                    "Membership": newMembership
//                ])
//                .eq("FineSet_id", value: fineSetId)
//                .execute()
//
//            perDayFine = newFine
//            membership = newMembership
//            isEditingFine = false
//            isEditingMembership = false
//        } catch {
//            // Check if the error is due to RLS (permission denied)
//            if error.localizedDescription.contains("permission denied") {
//                errorMessage = "Access denied: Admins only"
//            } else {
//                errorMessage = "Failed to update settings: \(error.localizedDescription)"
//            }
//        }
//    }
//
//    var body: some View {
//        ZStack {
//            Color.customBackground
//                .ignoresSafeArea()
//
//            VStack(spacing: 20) {
//                Text("Fine and Membership Management")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundStyle(Color.customText)
//                    .padding(.top, 20)
//
//                if isLoading {
//                    ProgressView("Loading...")
//                        .tint(Color.customText)
//                } else if let errorMessage = errorMessage {
//                    Text(errorMessage)
//                        .foregroundStyle(.red)
//                        .padding()
//                        .background(Color.red.opacity(0.1))
//                        .cornerRadius(10)
//                        .padding(.horizontal)
//                } else {
//                    // Per Day Fine Section
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text("Per Day Fine")
//                            .font(.headline)
//                            .foregroundStyle(Color.customText)
//
//                        HStack {
//                            if isEditingFine {
//                                TextField("Fine", text: $editedFine)
//                                    .textFieldStyle(.roundedBorder)
//                                    .frame(width: 100)
//                                    .keyboardType(.decimalPad)
//                            } else {
//                                Text(perDayFine != nil ? String(format: "%.2f", perDayFine!) : "Not Set")
//                                    .foregroundStyle(Color.customText)
//                            }
//                            Spacer()
//                            Button(action: {
//                                withAnimation {
//                                    isEditingFine.toggle()
//                                }
//                            }) {
//                                Image(systemName: "pencil")
//                                    .foregroundStyle(isEditingFine ? .green : Color.customText)
//                                    .padding(10)
//                                    .background(Color.white)
//                                    .clipShape(Circle())
//                                    .shadow(radius: 2)
//                            }
//                        }
//                    }
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(15)
//                    .shadow(radius: 5)
//                    .padding(.horizontal)
//
//                    // Membership Section
//                    VStack(alignment: .leading, spacing: 10) {
//                        Text("Membership Fee")
//                            .font(.headline)
//                            .foregroundStyle(Color.customText)
//
//                        HStack {
//                            if isEditingMembership {
//                                TextField("Membership", text: $editedMembership)
//                                    .textFieldStyle(.roundedBorder)
//                                    .frame(width: 100)
//                                    .keyboardType(.decimalPad)
//                            } else {
//                                Text(membership != nil ? String(format: "%.2f", membership!) : "Not Set")
//                                    .foregroundStyle(Color.customText)
//                            }
//                            Spacer()
//                            Button(action: {
//                                withAnimation {
//                                    isEditingMembership.toggle()
//                                }
//                            }) {
//                                Image(systemName: "pencil")
//                                    .foregroundStyle(isEditingMembership ? .green : Color.customText)
//                                    .padding(10)
//                                    .background(Color.white)
//                                    .clipShape(Circle())
//                                    .shadow(radius: 2)
//                            }
//                        }
//                    }
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(15)
//                    .shadow(radius: 5)
//                    .padding(.horizontal)
//
//                    // Update Button
//                    if isEditingFine || isEditingMembership {
//                        Button(action: {
//                            Task {
//                                await updateSettings()
//                            }
//                        }) {
//                            Text("Update")
//                                .font(.headline)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(
//                                    LinearGradient(
//                                        gradient: Gradient(colors: [.blue, .purple]),
//                                        startPoint: .leading,
//                                        endPoint: .trailing
//                                    )
//                                )
//                                .foregroundStyle(.white)
//                                .cornerRadius(15)
//                                .shadow(radius: 5)
//                        }
//                        .padding(.horizontal)
//                        .padding(.bottom, 20)
//                    }
//                }
//                Spacer()
//            }
//        }
//        .task {
//            await fetchSettings()
//        }
//    }
//}
//
//struct FineAndMembership: Decodable {
//    let fineSetId: String
//    let perDayFine: Double?
//    let membership: Double?
//
//    enum CodingKeys: String, CodingKey {
//        case fineSetId = "FineSet_id"
//        case perDayFine = "PerDayFine"
//        case membership = "Membership"
//    }
//}
//
//struct FineAndMembershipManagement_Previews: PreviewProvider {
//    static var previews: some View {
//        FineAndMembershipManagement()
//    }
//}
//
//
//
//
//
//
//
//
//
//

















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
    @State private var isEditing = false // Controls the overall editing mode

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
                        "PerDayFine": 1.0,
                        "Membership": 10.0
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
            isEditing = false // Exit editing mode
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
                Color.customBackground
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading...")
                        .tint(Color.customText)
                } else if let errorMessage = errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    Form {
                        Section(header: Text("Fine and Membership Settings")
                            .foregroundStyle(Color.customText)) {
                            // Per Day Fine Row
                            HStack {
                                Text("Per Day Fine")
                                    .foregroundStyle(Color.customText)
                                Spacer()
                                if isEditing {
                                    TextField("0.00", text: $editedFine)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(Color.customText)
                                } else {
                                    Text(perDayFine != nil ? String(format: "%.2f $", perDayFine!) : "Not Set")
                                        .foregroundStyle(.gray)
                                }
                            }

                            // Membership Fee Row
                            HStack {
                                Text("Membership Fee")
                                    .foregroundStyle(Color.customText)
                                Spacer()
                                if isEditing {
                                    TextField("0.00", text: $editedMembership)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(Color.customText)
                                } else {
                                    Text(membership != nil ? String(format: "%.2f $", membership!) : "Not Set")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                    .navigationTitle("Fine and Membership")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                if isEditing {
                                    // Save changes when "Done" is tapped
                                    Task {
                                        await updateSettings()
                                    }
                                } else {
                                    // Enter editing mode when "Edit" is tapped
                                    withAnimation {
                                        isEditing = true
                                    }
                                }
                            }) {
                                Text(isEditing ? "Done" : "Edit")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await fetchSettings()
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

struct FineAndMembershipManagement_Previews: PreviewProvider {
    static var previews: some View {
        FineAndMembershipManagement()
    }
}
