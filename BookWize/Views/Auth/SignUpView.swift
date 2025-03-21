import SwiftUI
import Supabase

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var gender = Gender.male
    @State private var selectedLibrary = Library.centralLibrary.rawValue
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(supabase: SupabaseClient) {
        _authService = StateObject(wrappedValue: AuthService(supabase: supabase))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                Picker("Gender", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
            }
            
            Section(header: Text("Library Selection")) {
                Picker("Preferred Library", selection: $selectedLibrary) {
                    ForEach(Library.allCases, id: \.rawValue) { library in
                        Text(library.rawValue).tag(library.rawValue)
                    }
                }
            }
            
            Section(header: Text("Security")) {
                SecureField("Password", text: $password)
                SecureField("Confirm Password", text: $confirmPassword)
            }
            
            Section {
                Button(action: {
                    Task {
                        await signUp()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading || !isValidForm)
            }
        }
        .navigationTitle("Create Account")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValidForm: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !name.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() async {
        isLoading = true
        
        do {
            let user = User(
                email: email,
                name: name,
                gender: gender,
                password: password,
                selectedLibrary: selectedLibrary,
                selectedGenres: [],
                role: .member
            )
            
            // Here you would typically call your auth service to create the user
            // For now, we'll just show a success message
            isLoading = false
            dismiss()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpView(
                supabase: SupabaseClient(
                    supabaseURL: URL(string: "https://example.com")!,
                    supabaseKey: ""
                )
            )
        }
    }
} 
