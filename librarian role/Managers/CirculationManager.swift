import Supabase
import Foundation

class CirculationManager: ObservableObject {
    static let shared = CirculationManager()
    
    func fetchBookByISBN(_ isbn: String) async throws -> Book {
        let response: [Book] = try await SupabaseManager.shared.client
            .from("books")
            .select()
            .eq("isbn", value: isbn)
            .execute()
            .value
        
        guard let book = response.first else {
            throw NSError(domain: "BookError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Book not found"])
        }
        
        return book
    }

    /// Issue a book and store in Supabase
    func issueBook(_ bookCirculation: BookCirculation, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("bookcirculation")
                    .insert(bookCirculation)
                    .execute()
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Error issuing book:", error)
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Fetch all issued books
    func fetchIssuedBooks(completion: @escaping ([BookCirculation]) -> Void) {
        Task {
            do {
                let loans: [BookCirculation] = try await SupabaseManager.shared.client
                    .from("bookcirculation")
                    .select()
                    .eq("status", value: "issued")
                    .execute()
                    .value
                
                DispatchQueue.main.async {
                    completion(loans)
                }
            } catch {
                print("Error fetching issued books:", error)
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
}

