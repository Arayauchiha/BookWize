import Supabase
import Foundation


    func issueBook(_ issuedBook: issueBooks, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // First, get the current available quantity
                let response = try await SupabaseManager.shared.client
                    .from("Books")
                    .select("availableQuantity")
                    .eq("isbn", value: issuedBook.isbn)
                    .single()
                    .execute()
                
                guard let data = response.data as? [[String: Any]],
                      let firstBook = data.first,
                      let currentQuantity = firstBook["available_quantity"] as? Int else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get book quantity"])
                }
                
                // Check if there are books available
                guard currentQuantity > 0 else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No books available"])
                }
                
                // Start a transaction to ensure both operations succeed or fail together
                try await SupabaseManager.shared.client.rpc("begin_transaction")
                
                // Insert the issued book record
                try await SupabaseManager.shared.client
                    .from("issuebooks")
                    .insert(issuedBook)
                    .execute()
                
                // Update the available quantity
                try await SupabaseManager.shared.client
                    .from("Books")
                    .update(["availableQuantity": currentQuantity - 1])
                    .eq("isbn", value: issuedBook.isbn)
                    .execute()
                
                // Commit the transaction
                try await SupabaseManager.shared.client.rpc("commit_transaction")
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Error issuing book:", error)
                // Rollback the transaction if it was started
                try? await SupabaseManager.shared.client.rpc("rollback_transaction")
                
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
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
    
    @Published var loans: [issueBooksCorrect] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func fetchIssuedBooks() async {
        //Runtime warning fix
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
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
                
                let issuedBooks = try decoder.decode([issueBooksCorrect].self, from: jsonData)
                
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
