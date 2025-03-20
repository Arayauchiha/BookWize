import Foundation

class FineManager: ObservableObject {
    @Published private(set) var fines: [Fine] = []
    @Published private(set) var overdueBooks: [CirculationRecord] = []
    private let saveKey = "library_fines"
    
    init() {
        loadFines()
    }
    
    func addFine(memberId: UUID, amount: Double, reason: FineReason) {
        let fine = Fine(
            id: UUID(),
            memberId: memberId,
            amount: amount,
            reason: reason,
            date: Date(),
            status: .pending
        )
        fines.append(fine)
        saveFines()
    }
    
    func updateOverdueBooks(_ records: [CirculationRecord]) {
        overdueBooks = records.filter { $0.isOverdue }
    }
    
    // MARK: - Persistence
    
    private func loadFines() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Fine].self, from: data) {
            fines = decoded
        }
    }
    
    private func saveFines() {
        if let encoded = try? JSONEncoder().encode(fines) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
} 