import Foundation

class UserManager: ObservableObject {
    @Published private(set) var members: [Member] = []
    private let saveKey = "library_members"
    
    init() {
        loadMembers()
    }
    
    func getMember(_ id: UUID) -> Member? {
        members.first { $0.id == id }
    }
    
    // MARK: - Persistence
    
    private func loadMembers() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Member].self, from: data) {
            members = decoded
        }
    }
    
    private func saveMembers() {
        if let encoded = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
} 
