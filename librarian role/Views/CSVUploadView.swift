import SwiftUI
import UniformTypeIdentifiers

struct CSVUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: InventoryManager
    @State private var showFilePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Instructions Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("CSV Upload Instructions")
                            .font(.title2)
                            .bold()
                        
                        Text("Please follow these steps to create your CSV file:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("1. Create a new spreadsheet in Excel, Numbers, or Google Sheets")
                            Text("2. Add the following columns in this exact order:")
                                .bold()
                            Group {
                                Text("• ISBN (required)")
                                Text("• Title (required)")
                                Text("• Author (required)")
                                Text("• Publisher (required)")
                                Text("• Quantity (required, must be a number)")
                                Text("• Published Date (optional)")
                                Text("• Description (optional)")
                                Text("• Page Count (optional, must be a number)")
                                Text("• Genre (required)")
                                Text("• Image URL (optional)")
                            }
                            .padding(.leading)
                            
                            Text("3. Add your book data to the spreadsheet")
                            Text("4. Save the file as CSV (Comma Separated Values)")
                            Text("5. Make sure the first row contains the column headers")
                        }
                        .padding(.leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Upload Button
                    Button(action: {
                        showFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Upload CSV File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    if isLoading {
                        ProgressView("Processing CSV...")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Bulk Upload Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let file = files.first else { return }
                    Task {
                        isLoading = true
                        do {
                            // Start accessing the security-scoped resource
                            guard file.startAccessingSecurityScopedResource() else {
                                throw NSError(domain: "FileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied to access the file"])
                            }
                            
                            defer {
                                file.stopAccessingSecurityScopedResource()
                            }
                            
                            try viewModel.importCSV(from: file)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                        isLoading = false
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

