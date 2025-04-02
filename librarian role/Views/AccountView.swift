import SwiftUI

struct AccountView: View {
    @Binding var isLoggedIn: Bool
    @State private var showingLogoutAlert = false
    @State private var showingChangePassword = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isNewPasswordVisible = false
    @State private var showingPasswordError = false
    @State private var errorMessage = ""
    @State private var showError = false
    @AppStorage("isLibrarianLoggedIn") private var isLibrarianLoggedIn = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("currentLibrarianEmail") private var currentLibrarianEmail: String?
    @State private var user: FetchAdmin?
    
    @State private var passwordValidation = ValidationUtils.PasswordValidation(
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasNumber: false,
        hasSpecialChar: false
    )

    struct FetchAdmin: Codable {
        var id: UUID
        var email: String
        var name: String
        var role: String?
    }
    
    struct FetchData: Codable {
        var email: String
        var password: String
    }
    
    private func fetchLibrarian() async {
        do {
            print("Starting fetchLibrarian...")
            
            var userEmail = currentLibrarianEmail
            print("Current librarian email from UserDefaults: \(String(describing: userEmail))")
            
            if userEmail == nil {
                print("No email in UserDefaults, trying to fetch librarian by role...")
                let response: [FetchAdmin] = try await SupabaseManager.shared.client
                    .from("Users")
                    .select("*")
                    .eq("roleFetched", value: "librarian")
                    .execute()
                    .value
                
                if let librarian = response.first {
                    userEmail = librarian.email
                    print("Found librarian by role: \(librarian.email)")
                }
            }
            
            guard let email = userEmail else {
                print("Could not find librarian email")
                return
            }
            
            print("Fetching user details for email: \(email)")
            
            let response: [FetchAdmin] = try await SupabaseManager.shared.client
                .from("Users")
                .select("*")
                .eq("email", value: email)
                .execute()
                .value
            
            print("Received response from database: \(response)")
            
            DispatchQueue.main.async {
                if let fetchedUser = response.first {
                    self.user = fetchedUser
                    if self.currentLibrarianEmail == nil {
                        self.currentLibrarianEmail = fetchedUser.email
                    }
                    print("Successfully set user data: \(fetchedUser.name), \(fetchedUser.email)")
                } else {
                    print("No user found in response")
                }
            }
        } catch {
            print("Error fetching librarian: \(error)")
        }
    }
    
    private func updatePassword() {
        guard let userEmail = user?.email else {
            errorMessage = "No librarian email found. Please try logging in again."
            showError = true
            return
        }
        
        print("Attempting to update password for librarian email: \(userEmail)")
        
        Task {
            do {
                let userData = FetchData(email: userEmail, password: newPassword)
                print("Sending update request to Users table with data:", userData)
                
                let response = try await SupabaseManager.shared.client
                    .from("Users")
                    .update(userData)
                    .eq("email", value: userEmail)
                    .execute()
                
                print("Password update response:", response)
                
                DispatchQueue.main.async {
                    print("Password successfully updated for librarian:", userEmail)
                    showingChangePassword = false
                    newPassword = ""
                    confirmPassword = ""
                }
            } catch {
                print("Error updating password:", error)
                DispatchQueue.main.async {
                    errorMessage = "Failed to update password: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.customButton)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let user = user {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.customText.opacity(0.6))
                            } else {
                                Text("Loading...")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account Settings") {
                    Button {
                        showingChangePassword = true
                    } label: {
                        Label("Change Password", systemImage: "lock.fill")
                    }
                    
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Account")
            .task {
                print("View appeared, fetching librarian data...")
                await fetchLibrarian()
            }
            .onChange(of: isLoggedIn) { newValue in
                if newValue {
                    print("Login state changed, fetching librarian data...")
                    Task {
                        await fetchLibrarian()
                    }
                }
            }
            .sheet(isPresented: $showingChangePassword) {
                NavigationView {
                    VStack(spacing: 20) {
                        Text("Enter your new password below")
                            .font(.subheadline)
                            .foregroundStyle(Color.customText.opacity(0.6))
                            .padding(.top, 20)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Password")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.customText.opacity(0.6))
                                
                                HStack {
                                    Group {
                                        if isNewPasswordVisible {
                                            TextField("Enter new password", text: $newPassword)
                                                .textContentType(.newPassword)
                                                .textInputAutocapitalization(.never)
                                                .onChange(of: newPassword) { newValue in
                                                    passwordValidation = ValidationUtils.validatePassword(newValue)
                                                }
                                        } else {
                                            SecureField("Enter new password", text: $newPassword)
                                                .textContentType(.newPassword)
                                                .textInputAutocapitalization(.never)
                                                .onChange(of: newPassword) { newValue in
                                                    passwordValidation = ValidationUtils.validatePassword(newValue)
                                                }
                                        }
                                    }
                                    
                                    Button(action: { isNewPasswordVisible.toggle() }) {
                                        Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(Color.customButton.opacity(0.6))
                                    }
                                }
                                .padding()
                                .background(Color.customInputBackground)
                                .cornerRadius(8)
                            }
                            .padding(.bottom, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password Requirements")
                                    .font(.caption)
                                    .foregroundStyle(Color.customText.opacity(0.7))
                                
                                HStack {
                                    Image(systemName: passwordValidation.hasMinLength ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordValidation.hasMinLength ? .green : .gray)
                                    Text("At least 8 characters")
                                        .font(.caption)
                                        .foregroundStyle(Color.customText.opacity(0.7))
                                }
                                
                                HStack {
                                    Image(systemName: passwordValidation.hasUppercase ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordValidation.hasUppercase ? .green : .gray)
                                    Text("One uppercase letter")
                                        .font(.caption)
                                        .foregroundStyle(Color.customText.opacity(0.7))
                                }
                                
                                HStack {
                                    Image(systemName: passwordValidation.hasLowercase ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordValidation.hasLowercase ? .green : .gray)
                                    Text("One lowercase letter")
                                        .font(.caption)
                                        .foregroundStyle(Color.customText.opacity(0.7))
                                }
                                
                                HStack {
                                    Image(systemName: passwordValidation.hasNumber ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordValidation.hasNumber ? .green : .gray)
                                    Text("One number")
                                        .font(.caption)
                                        .foregroundStyle(Color.customText.opacity(0.7))
                                }
                                
                                HStack {
                                    Image(systemName: passwordValidation.hasSpecialChar ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordValidation.hasSpecialChar ? .green : .gray)
                                    Text("One special character (@$!%*?&)")
                                        .font(.caption)
                                        .foregroundStyle(Color.customText.opacity(0.7))
                                }
                            }
                            .padding(.leading, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.customText.opacity(0.6))
                                
                                HStack {
                                    Group {
                                        if isNewPasswordVisible {
                                            TextField("Confirm new password", text: $confirmPassword)
                                                .textContentType(.newPassword)
                                                .textInputAutocapitalization(.never)
                                        } else {
                                            SecureField("Confirm new password", text: $confirmPassword)
                                                .textContentType(.newPassword)
                                                .textInputAutocapitalization(.never)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.customInputBackground)
                                .cornerRadius(8)
                                
                                HStack {
                                    Image(systemName: !confirmPassword.isEmpty && newPassword == confirmPassword ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(!confirmPassword.isEmpty && newPassword == confirmPassword ? .green : .gray)
                                    Text("Passwords match")
                                        .font(.caption)
                                        .foregroundStyle(Color.customText.opacity(0.7))
                                }
                                .padding(.leading, 4)
                            }
                            
                            Button(action: {
                                print("Update password button tapped")
                                updatePassword()
                            }) {
                                Text("Update Password")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.customButton)
                            )
                            .padding(.top, 16)
                            .disabled(newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword)
                            .opacity(newPassword.isEmpty || confirmPassword.isEmpty || !passwordValidation.isValid || newPassword != confirmPassword ? 0.7 : 1)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground)
                    .navigationTitle("Change Password")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingChangePassword = false
                                newPassword = ""
                                confirmPassword = ""
                            }
                            .foregroundStyle(Color.customButton)
                        }
                    }
                    .alert("Error", isPresented: $showError) {
                        Button("OK") { showError = false }
                    } message: {
                        Text(errorMessage)
                    }
                }
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    isLoggedIn = false
                    isLibrarianLoggedIn = false
                    NavigationUtil.popToRootView()
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    let window = windowScene?.windows.first
                    window?.rootViewController = UIHostingController(rootView: ContentView())
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}
