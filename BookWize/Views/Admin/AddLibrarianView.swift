import SwiftUI
import Supabase

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    private let authService: AuthService
    
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var selectedLibrary = Library.centralLibrary.rawValue
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    var body: some View {
        Form {
            Section(header: Text("Librarian Details")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
            }
            
            Section(header: Text("Library Assignment")) {
                Picker("Library", selection: $selectedLibrary) {
                    ForEach(Library.allCases, id: \.rawValue) { library in
                        Text(library.rawValue).tag(library.rawValue)
                    }
                }
            }
            
            Section {
                Button(action: {
                    Task {
                        await createLibrarian()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Add Librarian")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading || !isValidForm)
            }
        }
        .navigationTitle("Add Librarian")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Librarian account created successfully")
        }
    }
    
    private var isValidForm: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !name.isEmpty &&
        password.count >= 6 &&
        email.contains("@")
    }
    
    private func createLibrarian() async {
        isLoading = true
        
        do {
            try await authService.createLibrarian(
                email: email,
                password: password,
                name: name,
                library: selectedLibrary
            )
            isLoading = false
            showSuccess = true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        AddLibrarianView(
            authService: AuthService(
                supabase: SupabaseClient(
                    supabaseURL: URL(string: "https://example.com")!,
                    supabaseKey: ""
                )
            )
        )
    }
} 