import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var name: String
    var gender: Gender
    var password: String
    var selectedLibrary: String
    var selectedGenres: [String]
    var monthlyGoal: Int?
    
    init(id: UUID = UUID(), email: String, name: String, gender: Gender, password: String, selectedLibrary: String, selectedGenres: [String] = [], monthlyGoal: Int? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.gender = gender
        self.password = password
        self.selectedLibrary = selectedLibrary
        self.selectedGenres = selectedGenres
        self.monthlyGoal = monthlyGoal
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case gender
        case password
        case selectedLibrary = "selected_library"
        case selectedGenres = "selected_genres"
        case monthlyGoal = "monthly_goal"
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum Library: String,CaseIterable{
    case centralLibrary = "Central Library"
    case cityLibrary = "City Library"
}

//var selectedLibrary: [Library]

