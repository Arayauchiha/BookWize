import SwiftUI
struct NavigationUtil {
    static func popToRootView() {
        // Get all windows and filter for key window
        let windows = UIApplication.shared.windows.filter { $0.isKeyWindow }
        
        // For sheets and other modal presentations, we need to check all view controllers
        for window in windows {
            if let rootController = window.rootViewController {
                // Try to find navigation controller
                if let navController = findNavigationController(viewController: rootController) {
                    // Found a navigation controller, pop to its root
                    navController.popToRootViewController(animated: true)
                    return
                }
                
                // Check if there are any presented view controllers
                var currentController = rootController
                while let presentedController = currentController.presentedViewController {
                    if let navController = findNavigationController(viewController: presentedController) {
                        navController.popToRootViewController(animated: true)
                        return
                    }
                    currentController = presentedController
                }
            }
        }
    }
    
    static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        // If it's already a navigation controller, return it
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        // Check children recursively
        for childViewController in viewController.children {
            if let navigationController = childViewController as? UINavigationController {
                return navigationController
            }
            
            if let foundController = findNavigationController(viewController: childViewController) {
                return foundController
            }
        }
        
        return nil
    }
}
struct MembershipView: View {
    @State private var showPaymentSuccess = false
    @State private var navigateToGenres = false
    @State private var isLoading = false
    @State private var qrCodeImage: UIImage? = nil
    @State private var showDigitalCard = false
    @State private var showLogoutAlert = false
    @State private var showDigitalPass = false
    @State private var membershipAmount = 49.99 // Default value that will be updated
    @State private var isLoadingMembershipAmount = true
    
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
    
    private func fetchMembershipAmount() {
        isLoadingMembershipAmount = true
        
        Task {
            do {
                let response = try await SupabaseManager.shared.client.database
                    .from("FineAndMembershipSet")
                    .select("Membership")
                    .single()
                    .execute()
                
                // Debug: Print raw response data
                print("Raw response data:", String(data: response.data, encoding: .utf8) ?? "No data")
                
                // Try to decode the response
                do {
                    // Define a struct to decode the response
                    struct MembershipResponse: Decodable {
                        let Membership: Double
                    }
                    
                    let decodedResponse = try JSONDecoder().decode(MembershipResponse.self, from: response.data)
                    await MainActor.run {
                        self.membershipAmount = decodedResponse.Membership
                        self.isLoadingMembershipAmount = false
                    }
                    print("Fetched membership amount: $\(decodedResponse.Membership)")
                } catch {
                    print("Decoding error: \(error)")
                    await MainActor.run {
                        self.isLoadingMembershipAmount = false
                    }
                }
            } catch {
                print("Error fetching membership amount: \(error)")
                await MainActor.run {
                    self.isLoadingMembershipAmount = false
                }
            }
        }
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
                            
                            if isLoadingMembershipAmount {
                                ProgressView()
                                    .padding(5)
                            } else {
                                Text("$\(String(format: "%.2f", membershipAmount))")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(15)
                        
                        // Membership Perks
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Membership Perks")
                                .font(.headline)
                            
                            PerkRow(icon: "arrow.clockwise" , text: "Seamless smart card access")
                            PerkRow(icon: "star.fill", text: "Personalised Reading Logs")
                            PerkRow(icon: "book.fill" , text: "Book Reservations")
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
                    
                }
                .padding()
            }
            .navigationTitle("Membership")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(Color.customButton)
            })
            .onAppear {
                fetchMembershipAmount()
            }
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
    @State private var availableGenres: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    let userEmail: String
    
    var body: some View {
        ZStack {
            Color.customBackground.ignoresSafeArea()
            
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading genres...")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Error loading genres")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        fetchGenres()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else if availableGenres.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No genres found")
                        .font(.headline)
                    
                    Text("We couldn't find any genres in our catalog. Please proceed to continue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Continue") {
                        Task {
                            await saveSelectedGenres()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                List {
                    Section(header: Text("Select your preferred genres")) {
                        ForEach(availableGenres.sorted(), id: \.self) { genre in
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
                    }
                    
                    if !selectedGenres.isEmpty {
                        Section(footer: Text("You can always change your preferences later")) {
                            Text("\(selectedGenres.count) genre\(selectedGenres.count > 1 ? "s" : "") selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Genres")
        .navigationBarItems(trailing: Button("Done") {
            Task {
                await saveSelectedGenres()
            }
        }
        .disabled(isLoading))
        .onAppear {
            fetchGenres()
        }
    }
    
    private func fetchGenres() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let client = SupabaseManager.shared.client
                
                // Fetch all books to extract genres from categories
                let response = try await client.database
                    .from("Books")
                    .select("categories")
                    .execute()
                
                // Parse categories from each book to extract genres
                struct BookCategories: Codable {
                    let categories: [String]?
                }
                
                let decoder = JSONDecoder()
                let books = try decoder.decode([BookCategories].self, from: response.data)
                
                // Extract first category from each book as the genre
                var uniqueGenres = Set<String>()
                
                for book in books {
                    if let categories = book.categories, !categories.isEmpty {
                        // Use the first category as the main genre
                        let genre = categories[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !genre.isEmpty {
                            uniqueGenres.insert(genre)
                        }
                    }
                }
                
                await MainActor.run {
                    self.availableGenres = Array(uniqueGenres)
                    self.isLoading = false
                    print("Loaded \(uniqueGenres.count) unique genres from Books table")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load genres: \(error.localizedDescription)"
                    self.isLoading = false
                    print("Error fetching genres: \(error)")
                }
            }
        }
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
            
            // Fetch the complete user data to ensure we have the user ID
            let userResponse: [User] = try await client.database
                .from("Members")
                .select("*")
                .eq("email", value: userEmail)
                .execute()
                .value
            
            if let user = userResponse.first {
                // Store user data in UserDefaults
                UserDefaults.standard.set(user.id.uuidString, forKey: "currentMemberId")
                UserDefaults.standard.set(userEmail, forKey: "currentMemberEmail")
                
                // Set login status
                UserDefaults.standard.set(true, forKey: "isMemberLoggedIn")
                
                print("Successfully stored user data in UserDefaults")
                print("User ID: \(user.id.uuidString)")
                print("User Email: \(userEmail)")
            }
            
            // Navigate to Search_BrowseApp with selected genres
            DispatchQueue.main.async {
                NavigationUtil.popToRootView()
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let window = windowScene?.windows.first
                window?.rootViewController = UIHostingController(rootView: Search_BrowseApp(userPreferredGenres: Array(self.selectedGenres)))
            }
            
        } catch {
            print("Error saving selected genres: \(error)")
        }
    }
}

