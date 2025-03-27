import SwiftUI
import AVFoundation

struct ISBNScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var scannerModel = BarcodeScannerModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var bookImage: UIImage? = nil
    @State private var bookTitle: String = ""
    @State private var showBookPreview = false
    
    var body: some View {
        ZStack {
            CameraPreview(session: scannerModel.session)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Text("Position the barcode within the frame")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
            }
            
            // Scanning frame
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 250, height: 100)
                .padding()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading book data...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
            
            // Book preview overlay
            if showBookPreview {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    if let bookImage = bookImage {
                        Image(uiImage: bookImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "book.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .foregroundColor(.gray)
                    }
                    
                    Text(bookTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 30) {
                        Button(action: {
                            showBookPreview = false
                            scannerModel.resumeScanning()
                        }) {
                            Text("Scan Again")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            onScan(scannerModel.lastScannedCode ?? "")
                            dismiss()
                        }) {
                            Text("Use This Book")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            scannerModel.requestCameraPermission()
            scannerModel.onCodeScanned = { code in
                fetchBookData(isbn: code)
            }
        }
        .alert("Scanner Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func fetchBookData(isbn: String) {
        isLoading = true
        bookImage = nil
        bookTitle = ""
        
        // Create a URL for the Google Books API
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        guard let url = URL(string: urlString) else {
            showError("Invalid ISBN format")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    showError("Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    isLoading = false
                    showError("No data received")
                }
                return
            }
            
            do {
                // Parse the JSON response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   !items.isEmpty,
                   let volumeInfo = items[0]["volumeInfo"] as? [String: Any] {
                    
                    // Get book title
                    let title = volumeInfo["title"] as? String ?? "Unknown Title"
                    
                    // Get book image URL
                    var imageURL: URL? = nil
                    if let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
                       let thumbnailURLString = imageLinks["thumbnail"] as? String {
                        // Convert http to https if needed
                        let secureURLString = thumbnailURLString.replacingOccurrences(of: "http://", with: "https://")
                        imageURL = URL(string: secureURLString)
                    }
                    
                    // Store the scanned code
                    scannerModel.lastScannedCode = isbn
                    
                    // If we have an image URL, download the image
                    if let imageURL = imageURL {
                        downloadBookImage(from: imageURL) { image in
                            DispatchQueue.main.async {
                                isLoading = false
                                bookImage = image
                                bookTitle = title
                                showBookPreview = true
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            isLoading = false
                            bookTitle = title
                            showBookPreview = true
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        isLoading = false
                        showError("No book found with ISBN: \(isbn)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    showError("Error parsing data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    private func downloadBookImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
        scannerModel.resumeScanning()
    }
}

class BarcodeScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    var session = AVCaptureSession()
    var onCodeScanned: ((String) -> Void)?
    private var isConfigured = false
    var lastScannedCode: String? = nil
    
    override init() {
        super.init()
        setupSession()
    }
    
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if !session.isRunning {
                DispatchQueue.global(qos: .background).async {
                    self.session.startRunning()
                }
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        if !self.session.isRunning {
                            DispatchQueue.global(qos: .background).async {
                                self.session.startRunning()
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        // Only configure if not already configured
        guard !isConfigured else { return }
        
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if !session.inputs.contains(where: { $0 is AVCaptureDeviceInput }) {
            session.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if !session.outputs.contains(where: { $0 is AVCaptureMetadataOutput }) {
            session.addOutput(output)
            
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.ean13] // ISBN-13 format
        }
        
        session.commitConfiguration()
        isConfigured = true
    }
    
    func resumeScanning() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = metadataObject.stringValue {
            session.stopRunning()
            onCodeScanned?(code)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}
