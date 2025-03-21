import SwiftUI

struct CollectFineView: View {
    let member: Member
    let record: CirculationRecord
    @ObservedObject var fineManager: FineManager
    @Environment(\.dismiss) var dismiss
    
    @State private var amount: Double = 0
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var showingConfirmation = false
    
    private var calculatedFine: Double {
        let daysOverdue = Calendar.current.dateComponents([.day], from: record.dueDate, to: Date()).day ?? 0
        return Double(daysOverdue) * FineConstants.dailyOverdueFine
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Member Information")) {
                    LabeledContent("Name", value: member.name)
                    LabeledContent("Membership", value: member.membershipNumber)
                }
                
                Section(header: Text("Fine Details")) {
                    LabeledContent("Due Date", value: record.dueDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Days Overdue", value: "\(Calendar.current.dateComponents([.day], from: record.dueDate, to: Date()).day ?? 0)")
                    LabeledContent("Calculated Fine", value: "$\(calculatedFine)")
                }
                
                Section(header: Text("Payment Details")) {
                    TextField("Amount", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Collect Payment")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(amount <= 0)
                }
            }
            .navigationTitle("Collect Fine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Payment", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    collectPayment()
                }
            } message: {
                Text("Are you sure you want to collect $\(amount, specifier: "%.2f") from \(member.name)?")
            }
        }
    }
    
    private func collectPayment() {
        fineManager.addFine(
            memberId: member.id,
            amount: amount,
            reason: .overdue
        )
        dismiss()
    }
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case cash
    case card
    case check
    
    var id: String { self.rawValue }
} 
