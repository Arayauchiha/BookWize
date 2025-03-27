import Supabase
import Foundation

//class IssuedBookManager: ObservableObject {
//    static let shared = IssuedBookManager()
//    
//    @Published var bookTitle: String = ""
//    @Published var authorName: String = ""
//    @Published var memberEmail: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//
//    private init() {}
//
//    /// Fetch book details using ISBN from Supabase
////    func fetchBookDetails(isbn: String) async {
////        isLoading = true
////        errorMessage = nil
////
////        do {
////            let response = try await SupabaseManager.shared.client
////                .from("books")
////                .select("title, author")
////                .eq("isbn", value: isbn)
////                .single()
////                .execute()
////            
////            if let book = response.value as? [String: Any] {
////                await MainActor.run {
////                    bookTitle = book["title"] as? String ?? "Unknown"
////                    authorName = book["author"] as? String ?? "Unknown"
////                    isLoading = false
////                }
////            }
////        } catch {
////            await MainActor.run {
////                errorMessage = "Book not found."
////                isLoading = false
////            }
////        }
////    }
//
//
//    /// Fetch member details using scanned QR ID from Supabase
////    private func fetchMemberDetails(memberID: UUID) async {
////        isLoading = true
////        errorMessage = nil
////
////        do {
////            let response = try await SupabaseManager.shared.client
////                .from("members")
////                .select("email")
////                .eq("id", value: memberID)
////                .single()
////                .execute()
////            
////            if let member = response.value as? [String: Any] {
////                await MainActor.run {
////                    memberEmail = member["email"] as? String ?? "Unknown"
////                    isLoading = false
////                }
////            }
////        } catch {
////            await MainActor.run {
////                errorMessage = "Member not found."
////                isLoading = false
////            }
////        }
////    }
//
//    /// Issue a book and store it in Supabase
////    func issueBook(_ issuedBook: issueBooks, completion: @escaping (Bool) -> Void) {
////        Task {
////            do {
////                try await SupabaseManager.shared.client
////                    .from("issueBooks")
////                    .insert(issuedBook)
////                    .execute()
////                
////                DispatchQueue.main.async {
////                    completion(true)
////                }
////            } catch {
////                print("Error issuing book:", error)
////                DispatchQueue.main.async {
////                    completion(false)
////                }
////            }
////        }
////    }
//
//    /// Fetch all issued books
////    func fetchIssuedBooks(completion: @escaping ([issueBooks]) -> Void) {
////        Task {
////            do {
////                let issuedBooks: [issueBooks] = try await SupabaseManager.shared.client
////                    .from("issueBooks")
////                    .select()
////                    .execute()
////                    .value
////                
////                DispatchQueue.main.async {
////                    completion(issuedBooks)
////                }
////            } catch {
////                print("Error fetching issued books:", error)
////                DispatchQueue.main.async {
////                    completion([])
////                }
////            }
////        }
////    }
//}

class IssuedBookManager: ObservableObject {
    static let shared = IssuedBookManager()
    
    @Published var loans: [issueBooks] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func fetchIssuedBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select()
                .order("issue_date", ascending: false)
                .execute()
            
            // Print detailed debug information
            print("Response type: \(type(of: response))")
            print("Response data type: \(type(of: response.data))")
            print("Response data: \(String(describing: response.data))")
            
            // Try different approaches to extract data
            var jsonData: Data?
            
            // Check if data is an array of dictionaries
            if let dataArray = response.data as? [[String: Any]] {
                jsonData = try? JSONSerialization.data(withJSONObject: dataArray)
            }
            // Check if data is already a Data object
            else if let data = response.data as? Data {
                jsonData = data
            }
            
            // Decode if we have valid JSON data
            if let jsonData = jsonData {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let issuedBooks = try decoder.decode([issueBooks].self, from: jsonData)
                
                await MainActor.run {
                    self.loans = issuedBooks
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Unable to parse response data"
                    isLoading = false
                }
            }
        } catch {
            print("Fetch error: \(error)")
            await MainActor.run {
                errorMessage = "Failed to fetch issued books: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
