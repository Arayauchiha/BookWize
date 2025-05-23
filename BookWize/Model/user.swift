import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var name: String
    var gender: Gender
    var password: String
    var selectedLibrary: String
    var selectedGenres: [String]
    var fine: Double
    var monthlyGoal: Int?
    
    init(id: UUID = UUID(), email: String, name: String, gender: Gender, password: String, selectedLibrary: String, selectedGenres: [String] = [], fine: Double = 0, monthlyGoal: Int? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.gender = gender
        self.password = password
        self.selectedLibrary = selectedLibrary
        self.selectedGenres = selectedGenres
        self.fine = fine
        self.monthlyGoal = monthlyGoal
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

