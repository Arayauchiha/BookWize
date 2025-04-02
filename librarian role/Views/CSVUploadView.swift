import SwiftUI
import UniformTypeIdentifiers

// Spreadsheet Cell Styles
private struct SpreadsheetCell: View {
    let text: String
    let width: CGFloat
    let isHeader: Bool
    let isRequired: Bool
    
    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(isHeader ? .white : .primary)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isHeader ? Color.blue.opacity(0.9) :
                    Color.white
            )
            .overlay(
                isHeader && isRequired ?
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    : nil
            )
    }
}

struct CSVUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: InventoryManager
    @State private var showFilePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Column definitions with metadata
    private let columns = [
        (header: "ISBN", width: CGFloat(120), required: true, sample: "978-0-13-149505-0"),
        (header: "Title", width: CGFloat(150), required: true, sample: "The Great Gatsby"),
        (header: "Author", width: CGFloat(150), required: true, sample: "F. Scott Fitzgerald"),
        (header: "Publisher", width: CGFloat(120), required: true, sample: "Scribner"),
        (header: "Quantity", width: CGFloat(80), required: true, sample: "5"),
        (header: "Published Date", width: CGFloat(120), required: false, sample: "1925-04-10"),
        (header: "Description", width: CGFloat(200), required: false, sample: "A story of decadence and excess."),
        (header: "Page Count", width: CGFloat(100), required: false, sample: "180"),
        (header: "Genre", width: CGFloat(100), required: true, sample: "Classic"),
        (header: "Image URL", width: CGFloat(200), required: false, sample: "https://example.com/gatsby.jpg")
    ]
    
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
                    
                    // Template Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CSV Template Example")
                            .font(.title2)
                            .bold()
                        
                        Text("Scroll horizontally to view all columns. Required fields are marked with *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Column Headers
                                HStack(spacing: 0) {
                                    ForEach(columns, id: \.header) { column in
                                        SpreadsheetCell(
                                            text: column.header,
                                            width: column.width,
                                            isHeader: true,
                                            isRequired: column.required
                                        )
                                    }
                                }
                                
                                // Sample Data Row
                                HStack(spacing: 0) {
                                    ForEach(columns, id: \.header) { column in
                                        SpreadsheetCell(
                                            text: column.sample,
                                            width: column.width,
                                            isHeader: false,
                                            isRequired: false
                                        )
                                    }
                                }
                                .background(Color.white)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Legend
                        //                        HStack(spacing: 16) {
                        //                            Label {
                        //                                Text("Required Field")
                        //                                    .font(.caption)
                        //                            } icon: {
                        //                                Text("*")
                        //                                    .font(.caption)
                        //                                    .foregroundColor(.white)
                        //                                    .frame(width: 16, height: 16)
                        //                                    .background(Color.blue)
                        //                                    .cornerRadius(4)
                        //                            }
                        //
                        //                            Label {
                        //                                Text("Optional Field")
                        //                                    .font(.caption)
                        //                            } icon: {
                        //                                Rectangle()
                        //                                    .fill(Color.clear)
                        //                                    .frame(width: 16, height: 16)
                        //                                    .overlay(
                        //                                        RoundedRectangle(cornerRadius: 4)
                        //                                            .stroke(Color.gray, lineWidth: 1)
                        //                                    )
                        //                            }
                        //                        }
                        //                        .foregroundColor(.secondary)
                        //                    }
                        //                    .padding()
                        //                    .background(Color.gray.opacity(0.05))
                        //                    .cornerRadius(12)
                        
                        // Upload Button
                        Button(action: {
                            HapticManager.mediumImpact()
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
                            HapticManager.lightImpact()
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
                            HapticManager.mediumImpact()
                            do {
                                // Start accessing the security-scoped resource
                                guard file.startAccessingSecurityScopedResource() else {
                                    HapticManager.error()
                                    throw NSError(domain: "FileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied to access the file"])
                                }
                                
                                defer {
                                    file.stopAccessingSecurityScopedResource()
                                }
                                
                                try viewModel.importCSV(from: file)
                                HapticManager.success()
                                dismiss()
                            } catch {
                                HapticManager.error()
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                            isLoading = false
                        }
                    case .failure(let error):
                        HapticManager.error()
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {
                        HapticManager.lightImpact()
                    }
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }
    
}
