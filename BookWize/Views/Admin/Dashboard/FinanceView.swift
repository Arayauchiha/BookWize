import SwiftUI

struct FinanceView: View {
    @State private var showingAddExpense = false
    @State private var showingHistory = false
    @State private var searchText = ""
    @State private var selectedCategory = 0
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var expenses: [Expense] = []
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: Expense?
    @State private var editingExpense: Expense?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let categories = ["Librarian Salary", "Inventory", "Others"]
    
    var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty || 
                expense.title.localizedCaseInsensitiveContains(searchText)
            let matchesMonth = Calendar.current.isDate(expense.date, equalTo: selectedDate, toGranularity: .month)
            let matchesStatus = expense.status == "Pending"
            
            // If there's search text, only filter by search, month and status
            if !searchText.isEmpty {
                return matchesSearch && matchesMonth && matchesStatus
            }
            
            // If no search text, filter by category, month and status
            let matchesCategory = expense.category == categories[selectedCategory]
            return matchesCategory && matchesMonth && matchesStatus
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarPayouts(text: $searchText)
                    .padding()
                
                // Category Segmented Control
                if searchText.isEmpty {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(0..<categories.count, id: \.self) { index in
                            Text(categories[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .transition(.opacity)
                }
                
                // Month/Year Selection
                HStack {
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(selectedDate.formatted(.dateTime.month().year()))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                // Expenses List
                List {
                    ForEach(filteredExpenses) { expense in
                        ExpenseRow(expense: expense, onDelete: {
                            expenseToDelete = expense
                            showingDeleteAlert = true
                        }, onEdit: {
                            editingExpense = expense
                            showingAddExpense = true
                        })
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .background(Color.customBackground)
//            .navigationTitle("Payouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                        }
                        
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(expenses: $expenses, category: categories[selectedCategory], editingExpense: editingExpense)
                .onDisappear {
                    editingExpense = nil
                }
        }
        .sheet(isPresented: $showingHistory) {
            ExpenseHistoryView(expenses: $expenses)
        }
        .alert("Delete Expense", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
        } message: {
            Text("Are you sure you want to delete this expense?")
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
        .task {
            await loadExpenses()
        }
    }
    
    private func loadExpenses() async {
        isLoading = true
        do {
            let response = try await SupabaseManager.shared.client
                .from("payouts")
                .select()
                .execute()
            
            print("Raw Supabase response:", response.data) // Debug print
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: dateString) {
                    return date
                }
                
                let formatters: [DateFormatter] = [
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter
                    }()
                ]
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
            
            expenses = try decoder.decode([Expense].self, from: response.data)
        } catch {
            print("Decoding error:", error) // Debug print
            errorMessage = "Failed to load payouts: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func deleteExpense(_ expense: Expense) {
        Task {
            isLoading = true
            do {
                let _ = try await SupabaseManager.shared.client
                    .from("payouts")
                    .delete()
                    .eq("id", value: expense.id.uuidString)
                    .execute()
                
                if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                    expenses.remove(at: index)
                }
            } catch {
                errorMessage = "Failed to delete payout: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

struct SearchBarPayouts: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Search payouts...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 8)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.leading, 5)
        .padding(.trailing, 5)
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                HStack {
                    Text(expense.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(expense.status)
                        .font(.subheadline)
                        .foregroundColor(expense.status == "Pending" ? .orange : .green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("₹\(expense.amount, specifier: "%.2f")")
                    .font(.headline)
                Text(expense.date.formatted(.dateTime.day().month().year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct UpdatePayoutData: Encodable {
    let title: String
    let amount: Double
    let category: String
    let date: String
    let status: String
}

struct InsertPayoutData: Encodable {
    let id: String
    let title: String
    let amount: Double
    let category: String
    let date: String
    let status: String
}

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var expenses: [Expense]
    let category: String
    var editingExpense: Expense?
    
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory = 0
    @State private var status = "Pending"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let categories = ["Librarian Salary", "Inventory", "Others"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(0..<categories.count, id: \.self) { index in
                            Text(categories[index]).tag(index)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                if editingExpense != nil {
                    Section {
                        Picker("Status", selection: $status) {
                            Text("Pending").tag("Pending")
                            Text("Completed").tag("Completed")
                        }
                        .pickerStyle(.menu)
                        .tint(status == "Pending" ? .orange : .green)
                    }
                }
            }
            .navigationTitle(editingExpense == nil ? "Add New Payout" : "Edit Payout")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    Task {
                        await saveExpense()
                    }
                }
                .disabled(title.isEmpty || amount.isEmpty || isLoading)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if let expense = editingExpense {
                    // Fill fields for existing expense
                    title = expense.title
                    amount = String(format: "%.2f", expense.amount)
                    date = expense.date
                    selectedCategory = categories.firstIndex(of: expense.category) ?? 0
                    status = expense.status
                } else {
                    // Reset fields for new expense
                    title = ""
                    amount = ""
                    date = Date()
                    selectedCategory = categories.firstIndex(of: category) ?? 0
                    status = "Pending"
                }
            }
        }
    }
    
    private func saveExpense() async {
        
        isLoading = true
        do {
            if let amount = Double(amount), !title.isEmpty {
                if editingExpense != nil {
                    // Update existing expense
                    let updateData = UpdatePayoutData(
                        title: title,
                        amount: amount,
                        category: categories[selectedCategory],
                        date: ISO8601DateFormatter().string(from: date),
                        status: status
                    )
                    
                    let _ = try await SupabaseManager.shared.client
                        .from("payouts")
                        .update(updateData)
                        .eq("id", value: editingExpense!.id.uuidString)
                        .execute()
                    
                    if let index = expenses.firstIndex(where: { $0.id == editingExpense!.id }) {
                        let updatedExpense = Expense(
                            id: editingExpense!.id,
                            title: title,
                            amount: amount,
                            category: categories[selectedCategory],
                            date: date,
                            status: status
                        )
                        expenses[index] = updatedExpense
                    }
                } else {
                    // Add new expense
                    let newExpense = Expense(
                        title: title,
                        amount: amount,
                        category: categories[selectedCategory],
                        date: date,
                        status: "Pending"
                    )
                    
                    let insertData = InsertPayoutData(
                        id: newExpense.id.uuidString,
                        title: newExpense.title,
                        amount: newExpense.amount,
                        category: newExpense.category,
                        date: ISO8601DateFormatter().string(from: newExpense.date),
                        status: newExpense.status
                    )
                    
                    let _ = try await SupabaseManager.shared.client
                        .from("payouts")
                        .insert(insertData)
                        .execute()
                    
                    expenses.append(newExpense)
                }
                dismiss()
            }
        } catch {
            errorMessage = "Failed to save payout: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct ExpenseHistoryView: View {
    @Binding var expenses: [Expense]
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var completedExpenses: [Expense] {
        expenses.filter { $0.status == "Completed" }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            List(completedExpenses) { expense in
                VStack(alignment: .leading) {
                    Text(expense.title)
                        .font(.headline)
                    Text(expense.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("₹\(expense.amount, specifier: "%.2f")")
                        .font(.headline)
                    Text(expense.date.formatted(.dateTime.day().month().year()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Payout History")
            .navigationBarItems(
                leading: Button("Clear History") {
                    Task {
                        await clearHistory()
                    }
                }
                .foregroundColor(.red),
                trailing: Button("Done") { dismiss() }
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func clearHistory() async {
        isLoading = true
        do {
            // Only remove completed expenses from the local array
            expenses.removeAll { $0.status == "Completed" }
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            DatePicker(
                "Select Month",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            
            Button("Done") {
                // This button is now a placeholder
            }
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .padding()
        .frame(maxWidth: 350)
    }
}

struct Expense: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Double
    let category: String
    let date: Date
    var status: String
    
    init(id: UUID = UUID(), title: String, amount: Double, category: String, date: Date, status: String) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.status = status
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case amount
        case category
        case date
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        category = try container.decode(String.self, forKey: .category)
        date = try container.decode(Date.self, forKey: .date)
        status = try container.decode(String.self, forKey: .status)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(category, forKey: .category)
        try container.encode(date, forKey: .date)
        try container.encode(status, forKey: .status)
    }
}

#Preview {
    FinanceView()
        .environment(\.colorScheme, .light)
}




