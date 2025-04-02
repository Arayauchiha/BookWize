import Foundation

class FineCalculator {
    static let shared = FineCalculator()
    
    private init() {}
    
    // MARK: - Models
    struct IssueBook: Codable {
        let id: UUID
        let memberEmail: String
        let returnDate: String?
        let actualReturnedDate: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case memberEmail = "member_email"
            case returnDate = "return_date"
            case actualReturnedDate = "actual_returned_date"
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
            
            guard let perDayFine = fineSettings.first?.perDayFine else {
                print("No fine settings found")
                return
            }
            
            print("Per day fine: \(perDayFine)")
            
            // 2. Get all issue books (both returned and unreturned)
            let issueBooks: [IssueBook] = try await SupabaseManager.shared.client
                .from("issuebooks")
                .select("id, member_email, return_date, actual_returned_date")
                .execute()
                .value
            
            print("Found \(issueBooks.count) books")
            
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
            
            for book in issueBooks {
                print("\nProcessing book ID: \(book.id)")
                print("Member Email: \(book.memberEmail)")
                print("Return Date String: \(book.returnDate ?? "nil")")
                print("Actual Return Date String: \(book.actualReturnedDate ?? "nil")")
                
                guard let returnDateString = book.returnDate else {
                    print("Skipping - No return date")
                    continue
                }
                
                // Try to parse the return date
                var returnDate: Date?
                if let date = isoFormatter.date(from: returnDateString) {
                    returnDate = date
                    print("Parsed return date with ISO formatter")
                } else if let date = dateFormatter1.date(from: returnDateString) {
                    returnDate = date
                    print("Parsed return date with formatter 1")
                } else if let date = dateFormatter2.date(from: returnDateString) {
                    returnDate = date
                    print("Parsed return date with formatter 2")
                } else if let date = dateFormatter3.date(from: returnDateString) {
                    returnDate = date
                    print("Parsed return date with formatter 3")
                }
                
                guard let returnDate = returnDate else {
                    print("Failed to parse return date")
                    continue
                }
                
                // Determine the end date for fine calculation
                let endDate: Date
                if let actualReturnedDateString = book.actualReturnedDate {
                    print("Book has actual return date: \(actualReturnedDateString)")
                    // If book is returned, use actual return date
                    var actualReturnDate: Date?
                    if let date = isoFormatter.date(from: actualReturnedDateString) {
                        actualReturnDate = date
                        print("Parsed actual return date with ISO formatter")
                    } else if let date = dateFormatter1.date(from: actualReturnedDateString) {
                        actualReturnDate = date
                        print("Parsed actual return date with formatter 1")
                    } else if let date = dateFormatter2.date(from: actualReturnedDateString) {
                        actualReturnDate = date
                        print("Parsed actual return date with formatter 2")
                    } else if let date = dateFormatter3.date(from: actualReturnedDateString) {
                        actualReturnDate = date
                        print("Parsed actual return date with formatter 3")
                    }
                    
                    if let actualReturnDate = actualReturnDate {
                        endDate = actualReturnDate
                        print("Using actual return date for fine calculation")
                    } else {
                        print("Failed to parse actual return date, skipping book")
                        continue
                    }
                } else {
                    endDate = currentDate
                    print("Using current date for fine calculation")
                }
                
                // Calculate extra days
                let components = calendar.dateComponents([.day], from: returnDate, to: endDate)
                let days = components.day ?? 0
                
                print("Return date: \(returnDate)")
                print("End date: \(endDate)")
                print("Days difference: \(days)")
                
                if days > 0 {
                    let fine = Double(days) * perDayFine
                    let previousFine = memberFines[book.memberEmail] ?? 0
                    memberFines[book.memberEmail] = previousFine + fine
                    print("Calculated fine: \(fine)")
                    print("Previous fine: \(previousFine)")
                    print("Total fine for member: \(previousFine + fine)")
                } else {
                    print("No fine needed - not overdue")
                }
            }
            
            print("\nFinal member fines:")
            for (email, fine) in memberFines {
                print("\(email): \(fine)")
            }
            
            // 4. Get all members first
            let members: [User] = try await SupabaseManager.shared.client
                .from("Members")
                .select()
                .execute()
                .value
            
            // 5. Update fines for each member
            for member in members {
                let fine = memberFines[member.email] ?? 0.0
                do {
                    try await SupabaseManager.shared.client
                        .from("Members")
                        .update(["fine": fine])
                        .eq("email", value: member.email)
                        .execute()
                    print("Updated fine for \(member.email) to \(fine)")
                } catch {
                    print("Error updating member \(member.email):", error)
                }
            }
            
            print("Fine calculation completed successfully")
            
        } catch {
            print("Error in fine calculation process:", error)
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
