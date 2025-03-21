import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var name: String
    var gender: Gender
    var password: String
    var selectedLibrary: String?
    
    init(id: UUID = UUID(), email: String, name: String, gender: Gender, password: String, selectedLibrary: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.gender = gender
        self.password = password
        self.selectedLibrary = selectedLibrary
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

