import SwiftUI
import Combine

class WishlistSyncManager: ObservableObject {
    static let shared = WishlistSyncManager()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Set up notification observer for wishlist changes
        NotificationCenter.default.publisher(for: Notification.Name("RefreshBookStatus"))
            .sink { [weak self] _ in
                self?.syncWishlistWithManager()
            }
            .store(in: &cancellables)
    }
    
    func syncWishlistWithManager() {
        // This will be called when wishlist needs to be refreshed
        Task {
            do {
                guard let userId = UserDefaults.standard.string(forKey: "currentMemberId") else {
                    return
                }
                
                // Get wishlist from Supabase
                let response = try await SupabaseManager.shared.client
                    .from("Members")
                    .select("wishlist")
                    .eq("id", value: userId)
                    .execute()
                
                if let jsonString = String(data: response.data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                   let firstMember = jsonArray.first,
                   let wishlist = firstMember["wishlist"] as? [String] {
                    
                    // Clear existing wishlist in WishlistManager
                    WishlistManager.shared.clearWishlist()
                    
                    // Fetch ISBN for each book ID in wishlist
                    for bookId in wishlist {
                        do {
                            let bookResponse = try await SupabaseManager.shared.client
                                .from("Books")
                                .select("isbn")
                                .eq("id", value: bookId)
                                .execute()
                            
                            if let jsonStr = String(data: bookResponse.data, encoding: .utf8),
                               let jsonData = jsonStr.data(using: .utf8),
                               let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
                               let firstBook = jsonArray.first,
                               let isbn = firstBook["isbn"] as? String {
                                // Update WishlistManager with this ISBN
                                await MainActor.run {
                                    WishlistManager.shared.setInWishlist(isbn: isbn)
                                }
                            }
                        } catch {
                            print("Error fetching book ISBN: \(error)")
                        }
                    }
                    
                    print("Synchronized WishlistManager with \(wishlist.count) books from database")
                }
            } catch {
                print("Error syncing wishlist: \(error)")
            }
        }
    }
} 