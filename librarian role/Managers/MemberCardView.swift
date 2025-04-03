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
            return "person.circle.fill"
        case .female:
            return "person.circle.fill"
        case .other:
            return "person.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Avatar and Name
            HStack(spacing: 12) {
                // Avatar
                Image(systemName: genderIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(member.gender == .male ? .blue :
                                   member.gender == .female ? .purple : .gray)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(member.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            // Member Details
            VStack(alignment: .leading, spacing: 12) {
                // Library Card
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(.blue)
                    Text(member.selectedLibrary)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Fine Status
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(member.fine > 0 ? .red : .green)
                    Text("Fine: ₹\(String(format: "%.2f", member.fine))")
                        .font(.subheadline)
                        .foregroundStyle(member.fine > 0 ? .red : .green)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(member.fine > 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.customCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                Color.white.opacity(0.8)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
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

struct EditMemberSheet: View {
    let member: User
    @Binding var editedName: String
    let genderIcon: String
    let onSave: () async -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Name", text: $editedName)
                        .font(.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 4)
                } header: {
                    Text("Member Name")
                }
                
                Section {
                    InfoRow(icon: "envelope.fill", text: member.email)
                    InfoRow(icon: genderIcon, text: member.gender.rawValue)
                    InfoRow(icon: "books.vertical.fill", text: member.selectedLibrary)
                    InfoRow(icon: "dollarsign.circle.fill",
                           text: "₹\(String(format: "%.2f", member.fine))",
                           color: member.fine > 0 ? .red : .green)
                } header: {
                    Text("Member Information")
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onSave()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(editedName.isEmpty || editedName == member.name)
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    var color: Color = .secondary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .foregroundStyle(color)
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
