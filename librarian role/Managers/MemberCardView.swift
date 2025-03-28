import SwiftUI

struct MemberCardView: View {
    let member: User
    @State private var editedName: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingEditSheet = false
    
    init(member: User) {
        self.member = member
        _editedName = State(initialValue: member.name)
    }
    
    private var genderIcon: String {
        switch member.gender {
        case .male:
            return "person.badge.plus"
        case .female:
            return "person.badge.minus"
        case .other:
            return "person.circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(member.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.customText)
            
            MemberDetailsView(member: member, genderIcon: genderIcon)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.customCardBackground.opacity(0.7))
        )
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditMemberSheet(
                member: member,
                editedName: $editedName,
                genderIcon: genderIcon,
                onSave: updateName,
                onCancel: {
                    showingEditSheet = false
                    editedName = member.name
                }
            )
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func updateName() async {
        isLoading = true
        do {
            let _ = try await SupabaseManager.shared.client
                .from("Members")
                .update(["name": editedName])
                .eq("id", value: member.id.uuidString)
                .execute()
            
            showingEditSheet = false
            NotificationCenter.default.post(name: NSNotification.Name("RefreshMembers"), object: nil)
        } catch {
            print("Update error:", error)
            errorMessage = "Failed to update name: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct MemberDetailsView: View {
    let member: User
    let genderIcon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(member.email, systemImage: "envelope.fill")
            Label(member.gender.rawValue, systemImage: genderIcon)
            Label(member.selectedLibrary, systemImage: "books.vertical.fill")
            Label("₹\(String(format: "%.2f", member.fine))", systemImage: "dollarsign.circle.fill")
                .foregroundStyle(member.fine > 0 ? .red : .green)
        }
        .font(.system(size: 15))
        .foregroundStyle(Color.customText.opacity(0.6))
    }
}

struct EditMemberSheet: View {
    let member: User
    @Binding var editedName: String
    let genderIcon: String
    let onSave: () async -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $editedName)
                    .font(.system(size: 17))
                
                Text(member.email)
                    .foregroundStyle(Color.customText.opacity(0.6))
                
                Text(member.gender.rawValue)
                    .foregroundStyle(Color.customText.opacity(0.6))
                
                Text(member.selectedLibrary)
                    .foregroundStyle(Color.customText.opacity(0.6))
                
                Text("₹\(String(format: "%.2f", member.fine))")
                    .foregroundStyle(member.fine > 0 ? .red : .green)
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await onSave()
                        }
                    }
                    .disabled(editedName.isEmpty || editedName == member.name)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MemberCardView(member: User(
            id: UUID(),
            email: "john.doe@example.com",
            name: "John Doe",
            gender: .male,
            password: "password123",
            selectedLibrary: "Central Library",
            selectedGenres: [],
            fine: 50.0
        ))
        
        MemberCardView(member: User(
            id: UUID(),
            email: "jane.smith@example.com",
            name: "Jane Smith",
            gender: .female,
            password: "password123",
            selectedLibrary: "City Library",
            selectedGenres: [],
            fine: 0.0
        ))
    }
    .padding()
    .background(Color.customBackground)
} 
