import SwiftUI
import AVFoundation
import UIKit

struct SmartCardScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var scannerModel = SmartCardScannerModel()
    let onScan: (String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                CameraPreview(session: scannerModel.session)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Scanning frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 250, height: 150)
                        .overlay(
                            Text("Position smart card within frame")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                                .padding(.bottom, 20)
                        )
                    
                    Spacer()
                }
            }
            .navigationTitle("Scan Smart Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.lightImpact()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                HapticManager.mediumImpact()
                scannerModel.checkPermissions()
            }
            .onChange(of: scannerModel.scannedCode) { newValue in
                if let code = newValue {
                    HapticManager.success()
                    onScan(code)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

class SmartCardScannerModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    let session = AVCaptureSession()
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        HapticManager.success()
                        self?.startSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        HapticManager.error()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                HapticManager.error()
            }
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async {
                HapticManager.error()
            }
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            DispatchQueue.main.async {
                HapticManager.error()
            }
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            DispatchQueue.main.async {
                HapticManager.error()
            }
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .code128, .code39, .code93, .ean8, .ean13, .pdf417]
        } else {
            DispatchQueue.main.async {
                HapticManager.error()
            }
            return
        }
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            scannedCode = stringValue
        }
    }
}
