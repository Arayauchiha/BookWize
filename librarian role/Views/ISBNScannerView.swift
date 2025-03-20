import SwiftUI
import AVFoundation

struct ISBNScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var scannerModel = BarcodeScannerModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
        }
        .onAppear {
            scannerModel.requestCameraPermission()
            scannerModel.onCodeScanned = { code in
                onScan(code)
                dismiss()
            }
        }
        .alert("Scanner Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

class BarcodeScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    var session = AVCaptureSession()
    var onCodeScanned: ((String) -> Void)?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupSession()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.ean13] // ISBN-13 format
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
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