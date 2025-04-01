//import SwiftUI
//
//struct OverdueFineRow: View {
//    let record: CirculationRecord
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text(record.bookId.uuidString)
//                    .font(.headline)
//                Spacer()
////                Text("$\(calculateFine(), specifier: "%.2f")")
////                    .font(.headline)
////                    .foregroundColor(.red)
//            }
//            
//            HStack {
//                Text("Due Date: \(record.dueDate.formatted(date: .abbreviated, time: .omitted))")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Spacer()
//                
//                Text("\(daysOverdue) days overdue")
//                    .font(.subheadline)
//                    .foregroundColor(.red)
//            }
//        }
//        .padding(.vertical, 4)
//    }
//    
//    private var daysOverdue: Int {
//        Calendar.current.dateComponents([.day], from: record.dueDate, to: Date()).day ?? 0
//    }
////    
////    private func calculateFine() -> Double {
////        Double(daysOverdue) * FineConstants.dailyOverdueFine
////    }
//} 
