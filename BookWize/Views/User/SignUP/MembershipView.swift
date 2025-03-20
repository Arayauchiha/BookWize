import SwiftUI
import BookWize

struct NavigationUtil {
    static func popToRootView() {
        findNavigationController(viewController: UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController)?
            .popToRootViewController(animated: true)
    }
    
    static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        for childViewController in viewController.children {
            return findNavigationController(viewController: childViewController)
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
    let membershipAmount = 49.99
    
    // User information passed from SignupView
    let userName: String
    let userEmail: String
    
    init(userName: String, userEmail: String) {
        self.userName = userName
        self.userEmail = userEmail
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if !showDigitalCard {
                        // Library Card
                        VStack {
                            Text("Central Library")
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
                            PerkRow(icon: "person.2.fill", text: "Member-only Events")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(15)
                        
                        // Payment Button
                        Button(action: {
                            showPaymentSuccess = true
                        }) {
                            Text("Pay Now")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    } else {
                        // Digital Library Card
                        if let qrCodeImage = qrCodeImage {
                            DigitalLibraryCard(
                                userName: userName,
                                userEmail: userEmail,
                                libraryName: "Central Library",
                                qrCodeImage: qrCodeImage
                            )
                        }
                        
                        // Continue Button
                        NavigationLink(destination: GenreSelectionView()) {
                            Text("Continue to Genre Selection")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Membership")
            .alert("Payment Successful", isPresented: $showPaymentSuccess) {
                Button("Generate Digital Card") {
                    generateQRCode()
                }
            } message: {
                Text("Your membership has been activated successfully!")
            }
        }
    }
    
    // Generate QR Code using API
    func generateQRCode() {
        let userData = [
            "name": userName,
            "email": userEmail,
            "library": "Central Library",
            "membershipType": "Annual",
            "memberId": "LIB" + String(Int.random(in: 10000...99999)) // Generate a random member ID
        ]
        
        // Convert to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Start loading
            isLoading = true
            
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
                isLoading = false
                if let data = data, let image = UIImage(data: data) {
                    qrCodeImage = image
                    showDigitalCard = true
                }
            }
        }.resume()
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
                gradient: Gradient(colors: [Color.blue, Color.purple]),
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
            NavigationUtil.popToRootView()
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.rootViewController = UIHostingController(rootView: SearchBrowseView())
        })
    }
} 
