import Foundation

class FineCalculator {
    static let shared = FineCalculator()
    
    private init() {}
    
    // MARK: - Models
    struct IssueBook: Codable {
        let id: UUID
        let memberEmail: String
        let returnDate: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case memberEmail = "member_email"
            case returnDate = "return_date"
        }
    }
    
    struct FineSettings: Codable {
        let perDayFine: Double
        
        enum CodingKeys: String, CodingKey {
            case perDayFine = "PerDayFine"
        }
    }
    
    // MARK: - Fine Calculation
    func calculateAndUpdateFines() async {
        do {
            print("Starting fine calculation...")
            
            // 1. Get per day fine from FineAndMembershipSet
            let fineSettings: [FineSettings] = try await SupabaseManager.shared.client
                .from("FineAndMembershipSet")
                .select("PerDayFine")
                .execute()
                .value
            
            print("Fine settings raw response:", fineSettings)
            
            guard let perDayFine = fineSettings.first?.perDayFine else {
                print("No fine settings found")
                return
            }
            
            print("Per day fine: \(perDayFine)")
            
            // 2. Get all issue books with return dates
            let issueBooks: [IssueBook] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("id, member_email, return_date")
                .execute()
                .value
            
//            print("Issue books raw response:", issueBooks)
//            print("Fetched \(issueBooks.count) issue books")
            
            // 3. Calculate fines for each member
            var memberFines: [String: Double] = [:]
            let currentDate = Date()
            let calendar = Calendar.current
            
            // Create date formatters
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            let dateFormatter3 = DateFormatter()
            dateFormatter3.dateFormat = "yyyy-MM-dd"
            
            print("Current date for comparison:", currentDate)
            
            for book in issueBooks {
                print("\nProcessing book:", book.id)
                print("Member Email:", book.memberEmail)
                print("Return date string:", book.returnDate ?? "nil")
                
                guard let returnDateString = book.returnDate else {
                    print("Skipping book - no return date")
                    continue
                }
                
                // Try to parse the date with different formatters
                var returnDate: Date?
                
                // Try ISO8601 formatter first
                if let date = isoFormatter.date(from: returnDateString) {
                    returnDate = date
                    print("Successfully parsed date with ISO8601 formatter")
                }
                // Try other formatters if ISO8601 failed
                else if let date = dateFormatter1.date(from: returnDateString) {
                    returnDate = date
                    print("Successfully parsed date with formatter 1")
                }
                else if let date = dateFormatter2.date(from: returnDateString) {
                    returnDate = date
                    print("Successfully parsed date with formatter 2")
                }
                else if let date = dateFormatter3.date(from: returnDateString) {
                    returnDate = date
                    print("Successfully parsed date with formatter 3")
                }
                
                guard let returnDate = returnDate else {
                    print("Failed to parse return date with any formatter")
                    continue
                }
                
                print("Parsed return date:", returnDate)
                
                // Calculate extra days
                let components = calendar.dateComponents([.day], from: returnDate, to: currentDate)
                let days = components.day ?? 0
                print("Date components:", components)
                print("Extra days calculated:", days)
                
                if days > 0 {
                    let fine = Double(days) * perDayFine
                    let previousFine = memberFines[book.memberEmail] ?? 0
                    memberFines[book.memberEmail] = previousFine + fine
                    print("Previous fine: \(previousFine)")
                    print("Added fine: \(fine)")
                    print("Total fine now: \(memberFines[book.memberEmail] ?? 0)")
                } else {
                    print("No fine needed - not overdue")
                }
            }
            
            print("\nFinal member fines:", memberFines)
            print("Number of members with fines:", memberFines.count)
            
            // 4. Update fines in Members table
            for (memberEmail, fine) in memberFines {
                print("\nUpdating member with email:", memberEmail)
                print("Setting fine to:", fine)
                
                do {
                    let updateResponse = try await SupabaseManager.shared.client
                        .from("Members")
                        .update(["fine": fine])
                        .eq("email", value: memberEmail)
                        .execute()
                    
                    print("Update response for member \(memberEmail):", updateResponse)
                } catch {
                    print("Error updating member \(memberEmail):", error)
                    print("Error details:", error.localizedDescription)
                }
            }
            
            print("\nFine calculation completed successfully")
            
        } catch {
            print("Error in fine calculation process:", error)
            print("Error details:", error.localizedDescription)
        }
    }
}

// Helper extension for cleaner formatter setup
extension DateFormatter {
    func apply(_ block: (DateFormatter) -> Void) -> DateFormatter {
        block(self)
        return self
    }
} 
