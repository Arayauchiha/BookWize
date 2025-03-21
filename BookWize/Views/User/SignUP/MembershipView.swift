import SwiftUI

struct MembershipView: View {
    @State private var showPaymentSuccess = false
    @State private var navigateToGenres = false
    @State private var isLoading = false
    @State private var qrCodeImage: UIImage? = nil
    @State private var showDigitalCard = false
    @State private var showLogoutAlert = false
    @State private var showDigitalPass = false
    let membershipAmount = 49.99
    
    @AppStorage("isMemberLoggedIn") private var isMemberLoggedIn = false
    @Environment(\.dismiss) private var dismiss
    
    // User information passed from SignupView
    let userName: String
    let userEmail: String
    let selectedLibrary: String
    let userGender: Gender
    let userPassword: String
    @State private var selectedGenres: Set<String> = []
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    @State private var isProcessing = false
    
    init(userName: String, userEmail: String, selectedLibrary: String, gender: Gender, password: String) {
        self.userName = userName
        self.userEmail = userEmail
        self.selectedLibrary = selectedLibrary
        self.userGender = gender
        self.userPassword = password
    }
    
    private func saveUserData() async throws {
        let client = SupabaseManager.shared.client
        
        let user = User(
            email: userEmail,
            name: userName,
            gender: userGender,
            password: userPassword,
            selectedLibrary: selectedLibrary,
            selectedGenres: Array(selectedGenres)
        )
        
        do {
            let response = try await client.database
                .from("Members")
                .insert(user)
                .execute()
            
            print("Successfully saved user data to Supabase")
            
            // Send welcome email
            let emailService = EmailService()
            let subject = "Welcome to BookWize!"
            let body = """
            Hello \(userName),
            
            Welcome to BookWize! Your account has been successfully created.
            
            Your selected library: \(selectedLibrary)
            
            You can now enjoy all the benefits of our library management system.
            
            Regards,
            BookWize Team
            """
            
            let emailSent = await emailService.sendEmail(to: userEmail, subject: subject, body: body)
            print("Welcome email sent: \(emailSent)")
            
        } catch {
            print("Error saving user data: \(error)")
            throw error
        }
    }
    
    // Generate QR Code using API
    func generateQRCode() {
        let userData = [
            "name": userName,
            "email": userEmail,
            "library": selectedLibrary,
            "membershipType": "Annual",
            "memberId": "LIB" + String(Int.random(in: 10000...99999)) // Generate a random member ID
        ]
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Start loading
            isProcessing = true
            
            // Call QR code API
            let apiUrl = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=\(jsonString)"
            if let url = URL(string: apiUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
                fetchQRCode(from: url)
            }
        }
    }
    
    // Fetch QR Code from API
    func fetchQRCode(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                if let data = data, let image = UIImage(data: data) {
                    self.qrCodeImage = image
                    self.showDigitalCard = true
                }
            }
        }.resume()
    }
    
    private func handlePaymentAndSaveData() {
        // Simulate payment process
        isProcessing = true
        
        // Clear any previous error message
        errorMessage = nil
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Task {
                do {
                    // Save user data to Supabase
                    try await saveUserData()
                    
                    // Show success alert
                    self.showSuccessAlert = true
                    
                    // Set processing to false
                    self.isProcessing = false
                    
                } catch {
                    print("Error during payment process: \(error)")
                    self.errorMessage = "Error processing payment: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !showDigitalCard {
                        // Library Card
                        VStack {
                            Text(selectedLibrary)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Annual Membership")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                        
                        // Membership Amount
                        VStack {
                            Text("Membership Amount")
                                .font(.headline)
                            Text("$\(String(format: "%.2f", membershipAmount))")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                        
                        // Membership Perks
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Membership Perks")
                                .font(.headline)
                            
                            PerkRow(icon: "book.fill", text: "Advance Book Reservation")
                            PerkRow(icon: "star.fill", text: "Access to Popular Books Catalog")
                            PerkRow(icon: "arrow.clockwise", text: "Book Renewal Option")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(15)
                        
                        // Payment Button
                        Button(action: {
                            handlePaymentAndSaveData()
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Pay Now")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.customButton)
                        .cornerRadius(10)
                        .disabled(isProcessing)
                        .padding(.horizontal)
                        
                        // Show error message if any
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                    } else {
                        // Digital Library Card
                        if let qrCodeImage = qrCodeImage {
                            DigitalLibraryCard(
                                userName: userName,
                                userEmail: userEmail,
                                libraryName: selectedLibrary,
                                qrCodeImage: qrCodeImage
                            )
                        }
                        
                        // Continue Button
                        NavigationLink(destination: GenreSelectionView(userEmail: userEmail)) {
                            Text("Continue to Genre Selection")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.customButton)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Logout Button
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.customButton)
                        .cornerRadius(10)
                    }
                    .padding(.top, 30)
                }
                .padding()
            }
            .navigationTitle("Membership")
            .alert("Payment Successful!", isPresented: $showSuccessAlert) {
                Button("Generate Digital Card") {
                    generateQRCode()
                }
            } message: {
                Text("Your membership has been activated successfully!")
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    isMemberLoggedIn = false
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .background(Color.customBackground)
        }
    }
}

struct PerkRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

struct DigitalLibraryCard: View {
    var userName: String
    var userEmail: String
    var libraryName: String
    var qrCodeImage: UIImage
    
    var body: some View {
        VStack(spacing: 16) {
            // Library Icon and Name
            HStack {
                Image(systemName: "building.columns.fill")
                    .font(.title)
                    .foregroundColor(.white)
                Text(libraryName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // User Information
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                    Text(userName)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.white)
                    Text(userEmail)
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            
            // QR Code
            Image(uiImage: qrCodeImage)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(.vertical, 10)
            
            // Footer
            Text("Scan this QR code to access your library account")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.customButton, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

struct GenreSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedGenres: Set<String> = []
    let userEmail: String
    
    let genres = [
        "Fiction", "Non-Fiction", "Mystery", "Romance", "Science Fiction",
        "Fantasy", "Biography", "History", "Poetry", "Children's Books"
    ]
    
    var body: some View {
        List(genres, id: \.self) { genre in
            Button(action: {
                if selectedGenres.contains(genre) {
                    selectedGenres.remove(genre)
                } else {
                    selectedGenres.insert(genre)
                }
            }) {
                HStack {
                    Text(genre)
                    Spacer()
                    if selectedGenres.contains(genre) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Select Genres")
        .navigationBarItems(trailing: Button("Done") {
            Task {
                await saveSelectedGenres()
            }
        })
        .background(Color.customBackground)
    }
    
    private func saveSelectedGenres() async {
        let client = SupabaseManager.shared.client
        
        do {
            // Update the selectedGenres column for the user
            let response = try await client.database
                .from("Members")
                .update(["selectedGenres": Array(selectedGenres)])
                .eq("email", value: userEmail)
                .execute()
            
            print("Successfully saved selected genres to Supabase")
            dismiss()
            
        } catch {
            print("Error saving selected genres: \(error)")
        }
    }
}
