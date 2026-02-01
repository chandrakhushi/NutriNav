//
//  BarcodeScannerView.swift
//  NutriNav
//
//  Native iOS barcode scanner using AVFoundation
//  Supports UPC-A, UPC-E, EAN-8, EAN-13, and QR codes
//

import SwiftUI
import AVFoundation

// MARK: - Barcode Scanner Coordinator

class BarcodeScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var parent: BarcodeScannerRepresentable
    var didFindCode: ((String) -> Void)?
    private var lastScannedCode: String?
    private var lastScanTime: Date?
    
    init(_ parent: BarcodeScannerRepresentable) {
        self.parent = parent
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Get the first barcode
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        // Debounce - avoid scanning same code repeatedly
        let now = Date()
        if let lastCode = lastScannedCode, let lastTime = lastScanTime,
           lastCode == stringValue && now.timeIntervalSince(lastTime) < 2.0 {
            return
        }
        
        lastScannedCode = stringValue
        lastScanTime = now
        
        // Haptic feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        // Callback on main thread
        DispatchQueue.main.async {
            self.didFindCode?(stringValue)
        }
    }
}

// MARK: - Barcode Scanner UIView Representable

struct BarcodeScannerRepresentable: UIViewRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeCoordinator() -> BarcodeScannerCoordinator {
        let coordinator = BarcodeScannerCoordinator(self)
        coordinator.didFindCode = onCodeScanned
        return coordinator
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        // Check camera authorization
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera(in: view, context: context)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera(in: view, context: context)
                    }
                }
            }
        default:
            // Camera access denied
            let label = UILabel()
            label.text = "Camera access required"
            label.textColor = .white
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func setupCamera(in view: UIView, context: Context) {
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
                // Supported barcode types
                output.metadataObjectTypes = [
                    .ean8,
                    .ean13,
                    .upce,
                    .code128,
                    .code39,
                    .code93,
                    .qr
                ]
            }
            
            // Add preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Store preview layer for resize
            view.layer.setValue(previewLayer, forKey: "previewLayer")
            
            // Start session on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            
        } catch {
            print("Camera setup error: \(error)")
        }
    }
}

// MARK: - Barcode Scanner View

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    let onScan: (ScannedFoodResult) -> Void
    
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var torchOn = false
    
    private let openFoodFactsService = OpenFoodFactsService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                BarcodeScannerRepresentable { barcode in
                    handleScannedBarcode(barcode)
                }
                .ignoresSafeArea()
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanning frame
                    ZStack {
                        // Darkened overlay with cutout
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .mask(
                                ZStack {
                                    Rectangle()
                                    RoundedRectangle(cornerRadius: 20)
                                        .frame(width: 280, height: 180)
                                        .blendMode(.destinationOut)
                                }
                                .compositingGroup()
                            )
                        
                        // Scanning frame border
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 280, height: 180)
                        
                        // Scanning line animation
                        if !isProcessing {
                            ScanLineView()
                                .frame(width: 260, height: 2)
                        }
                    }
                    .frame(height: 300)
                    
                    Spacer()
                    
                    // Bottom info
                    VStack(spacing: Spacing.md) {
                        if isProcessing {
                            HStack(spacing: Spacing.sm) {
                                ProgressView()
                                    .tint(.white)
                                Text("Looking up product...")
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text("Point camera at barcode")
                                .font(.h3)
                                .foregroundColor(.white)
                            
                            Text("UPC, EAN, and QR codes supported")
                                .font(.bodySmall)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 60)
                }
                
                // Torch button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: toggleTorch) {
                            Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Product Not Found", isPresented: $showError) {
                Button("Try Again", role: .cancel) {
                    errorMessage = nil
                }
                Button("Manual Entry") {
                    dismiss()
                }
            } message: {
                Text(errorMessage ?? "Could not find this product. Try scanning again or enter manually.")
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        guard !isProcessing else { return }
        
        isProcessing = true
        HapticFeedback.impact()
        
        Task {
            do {
                let result = try await openFoodFactsService.lookupBarcode(barcode)
                
                await MainActor.run {
                    isProcessing = false
                    HapticFeedback.success()
                    onScan(result)
                    dismiss()
                }
            } catch let error as OpenFoodFactsError {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.errorDescription
                    showError = true
                    HapticFeedback.error()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
    
    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = torchOn ? .off : .on
            torchOn.toggle()
            device.unlockForConfiguration()
            HapticFeedback.selection()
        } catch {
            print("Torch error: \(error)")
        }
    }
}

// MARK: - Scanning Line Animation

struct ScanLineView: View {
    @State private var offset: CGFloat = -80
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .green, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 80
                }
            }
    }
}

