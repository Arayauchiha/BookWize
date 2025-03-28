import Supabase
import Foundation

class IssuedBookManager: ObservableObject {
    static let shared = IssuedBookManager()
    
    @Published var loans: [issueBooks] = []
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
