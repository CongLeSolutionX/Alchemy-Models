//
//  YOLOv3CameraView_V4.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/21/25.
//
import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit
import Combine // <-- Import Combine

// MARK: - Detection Model (Unchanged)

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect // normalized (0…1)
    let label: String
    let confidence: VNConfidence
}

// MARK: - Available YOLO Models Enum

enum YOLOModel: String, CaseIterable, Identifiable {
    // --- Add cases matching the FILENAMES (without .mlpackage) of the models ---
    // --- you've added to your Xcode project.                      ---
    case yolo11l = "yolo11l" // Assumes you have "yolo11l.mlpackage"
    case yolo11m = "yolo11m" // Assumes you have "yolo11m.mlpackage"
    case yolo11n = "yolo11n" // Assumes you have "yolo11n.mlpackage"
    case yolo11s = "yolo11s" // Assumes you have "yolo11s.mlpackage"
    case yolo11x = "yolo11x" // Assumes you have "yolo11x.mlpackage"
    // Add more object detection models here if needed
    
    var id: String { self.rawValue }
    
    var displayName: String {
        // Provide slightly nicer names for the picker
        switch self {
        case .yolo11l: return "YOLOv11 Large"
        case .yolo11m: return "YOLOv11 Medium"
        case .yolo11n: return "YOLOv11 Nano"
        case .yolo11s: return "YOLOv11 Small"
        case .yolo11x: return "YOLOv11 XLarge"
        }
    }
    
    // Helper to get the compiled model instance
    // IMPORTANT: This assumes the compiled names match the enum rawValues.
    // Xcode compiles `YourModel.mlpackage` into a class named `YourModel`.
    func loadCompiledModel() -> MLModel? {
        // Use switch or dynamic loading if class names differ significantly,
        // but typically they match the mlpackage name.
        switch self {
        case .yolo11l: return try? yolo11l(configuration: .init()).model
        case .yolo11m: return try? yolo11m(configuration: .init()).model
        case .yolo11n: return try? yolo11n(configuration: .init()).model
        case .yolo11s: return try? yolo11s(configuration: .init()).model
        case .yolo11x: return try? yolo11x(configuration: .init()).model
            // Add cases for other models here
        }
    }
}

// MARK: - Camera + Vision Coordinator (Updated)

class CameraViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var detections: [Detection] = []
    @Published var selectedModel: YOLOModel = .yolo11n // Default model
    @Published var modelLoadError: String? = nil
    
    // MARK: - Private Properties
    let session = AVCaptureSession()
    private var visionRequest: VNCoreMLRequest?
    private var cancellables = Set<AnyCancellable>() // For Combine subscriptions
    
    // MARK: - Initialization
    override init() {
        super.init()
        configureSession() // Configure camera first
        setupBindings()    // Setup model change listener
        // Initial model load is triggered by the binding via selectedModel's default value
    }
    
    // MARK: - Model Configuration (Dynamic)
    private func loadModel(modelType: YOLOModel) {
        print("🔄 Attempting to load model: \(modelType.rawValue)")
        modelLoadError = nil // Clear previous errors
        detections = []     // Clear detections from old model
        
        guard let model = modelType.loadCompiledModel() else {
            let errorMsg = "❌ Failed to load compiled model: \(modelType.rawValue). Did you add it to the project?"
            print(errorMsg)
            modelLoadError = errorMsg
            visionRequest = nil // Ensure no old request is used
            return
        }
        
        guard let vnModel = try? VNCoreMLModel(for: model) else {
            let errorMsg = "❌ Failed to create VNCoreMLModel for: \(modelType.rawValue)"
            print(errorMsg)
            modelLoadError = errorMsg
            visionRequest = nil
            return
        }
        
        // Create a new request for the selected model
        let req = VNCoreMLRequest(model: vnModel, completionHandler: handleDetections)
        req.imageCropAndScaleOption = .scaleFill // Or other options as needed
        
        self.visionRequest = req // Assign the new request
        print("✅ Successfully loaded model: \(modelType.rawValue)")
    }
    
    // MARK: - Session Configuration (Unchanged from original)
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high // Consider alternatives like .photo for higher res if needed
        
        // 1) Camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("❌ Cannot access camera")
            modelLoadError = "Cannot access camera" // Show error
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        
        // 2) Video output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        // Ensure frames are delivered on a specific queue
        output.setSampleBufferDelegate(self,
                                       queue: DispatchQueue(label: "videoQueue", qos: .userInitiated))
        // Discard frames if the processing queue is busy
        output.alwaysDiscardsLateVideoFrames = true
        session.addOutput(output)
        
        // --- Set Output Orientation ---
        // Needed because connection orientation doesn't auto-update with device rotation
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait // Set initial orientation
            }
            // Enable mirroring only if using the front camera
            if device.position == .front && connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        // --- End Set Output Orientation ---
        
        session.commitConfiguration()
    }
    
    // MARK: - Bindings (Listen for Model Changes)
    private func setupBindings() {
        $selectedModel
            .receive(on: DispatchQueue.global(qos: .userInitiated)) // Load model off main thread
            .sink { [weak self] newModel in
                self?.loadModel(modelType: newModel)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Start / Stop (Unchanged)
    func start() {
        // Check if session is already running to avoid issues
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            print("🚀 Camera Session Started")
        }
    }
    
    func stop() {
        // Check if session is running before stopping
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
            print("🛑 Camera Session Stopped")
        }
    }
    
    // MARK: - Handle Vision Results (Mostly Unchanged)
    // This assumes all loaded models output VNRecognizedObjectObservation
    private func handleDetections(request: VNRequest, error: Error?) {
        // Handle potential errors from the Vision request itself
        if let error = error {
            print("❌ Vision request error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.modelLoadError = "Vision processing error: \(error.localizedDescription)"
            }
            return
        }
        
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            // This might happen if the wrong model type (e.g., classification) was loaded
            print("⚠️ Vision results are not VNRecognizedObjectObservation.")
            // Optionally clear detections or show a specific error
            DispatchQueue.main.async {
                // self.modelLoadError = "Model output type mismatch."
                self.detections = [] // Clear previous detections
            }
            return
        }
        
        let dets = observations.compactMap { obs -> Detection? in
            // Check confidence threshold if needed
            // guard obs.confidence > 0.5 else { return nil }
            guard let topLabel = obs.labels.first else { return nil } // Should have at least one label
            
            return Detection(boundingBox: obs.boundingBox,
                             label: topLabel.identifier,
                             confidence: topLabel.confidence)
        }
        
        // Publish detections on the main thread for UI updates
        DispatchQueue.main.async {
            self.detections = dets
            // Optionally clear error message on successful detection
            if !dets.isEmpty && self.modelLoadError != nil {
                self.modelLoadError = nil
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate (Updated)
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        // Ensure we have a valid request and pixel buffer
        guard let currentRequest = self.visionRequest, // Use the potentially updated request
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            // print("Delegate called but no request or pixel buffer") // Debugging
            return
        }
        
        // --- Determine Correct Orientation ---
        // Get current device orientation dynamically if possible,
        // or use the connection's static orientation set earlier.
        // Note: UI orientation != device orientation sometimes.
        // Here we assume the video connection's orientation is sufficient
        // because we set it in configureSession.
        let imageOrientation: CGImagePropertyOrientation
        switch connection.videoOrientation {
        case .portrait: imageOrientation = .up
        case .portraitUpsideDown: imageOrientation = .down
        case .landscapeRight: imageOrientation = .right // Note: This might be counter-intuitive; image is rotated 90 deg clockwise relative to device held portrait
        case .landscapeLeft: imageOrientation = .left   // Note: Rotated 90 deg counter-clockwise
        @unknown default: imageOrientation = .up
        }
        // --- End Determine Correct Orientation ---
        
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: imageOrientation, // Pass the determined orientation
            options: [:] // Add request-specific options here if needed
        )
        
        do {
            try handler.perform([currentRequest])
        } catch {
            print("❌ Failed to perform Vision request: \(error)")
            DispatchQueue.main.async {
                self.modelLoadError = "Vision handler error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - UIKit Preview Layer Wrapper (Unchanged)

fileprivate class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - SwiftUI Camera Preview Wrapper (Updated for Orientation)

fileprivate struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let pl = view.videoPreviewLayer
        pl.session = session
        pl.videoGravity = .resizeAspectFill
        
        // --- Set Preview Layer Orientation ---
        // This ensures the *preview* matches the camera's orientation setup
        if let connection = pl.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait // Match the data output orientation
        }
        // Enable mirroring only if using the front camera - match data output
        if let input = session.inputs.first as? AVCaptureDeviceInput,
           input.device.position == .front,
           let connection = pl.connection,
           connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
        // --- End Set Preview Layer Orientation ---
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // No update needed as layer handles resizing.
        // Orientation changes should be handled via connection if dynamic updates are needed,
        // but for a fixed orientation app, makeUIView is sufficient.
    }
}

// MARK: - Main SwiftUI View (Updated)

struct YOLOv3CameraView_V3: View { // Renamed view struct
    @StateObject private var vm = CameraViewModel()
    
    var body: some View {
        NavigationView { // Add NavigationView for title/toolbar placement
            GeometryReader { geo in
                ZStack {
                    // Live camera feed covering the whole screen
                    CameraPreview(session: vm.session)
                        .ignoresSafeArea()
                    
                    // Overlay Bounding boxes + labels
                    ForEach(vm.detections) { det in
                        drawDetection(detection: det, geometry: geo)
                    }
                    
                    // Error Message Overlay
                    if let errorMsg = vm.modelLoadError {
                        errorOverlay(message: errorMsg)
                    }
                    
                    // --- Model Picker UI ---
                    VStack {
                        Spacer() // Pushes picker to the bottom
                        modelPicker()
                            .padding(.bottom, 20) // Add some spacing from the edge
                    }
                    // --- End Model Picker UI ---
                    
                }
                // Use Toolbar for title and potentially other controls
                .toolbar {
                    ToolbarItem(placement: .principal) { // Center title
                        Text("YOLO Object Detection")
                            .font(.headline)
                    }
                }
                .navigationBarTitleDisplayMode(.inline) // Keep title inline
                
            } // End GeometryReader
            .onAppear { vm.start() }
            .onDisappear { vm.stop() }
        } // End NavigationView
        .statusBarHidden(true) // Optional: Hide status bar for full-screen feel
    }
    
    // --- Helper Functions for UI Elements ---
    
    // Draws a single detection box and label
    @ViewBuilder
    private func drawDetection(detection: Detection, geometry: GeometryProxy) -> some View {
        let rect = detection.boundingBox
        // Convert normalized coordinates (Vision origin bottom-left) to SwiftUI coordinates (origin top-left)
        let x = rect.minX * geometry.size.width
        let y = (1 - rect.maxY) * geometry.size.height // Use maxY for top edge
        let w = rect.width * geometry.size.width
        let h = rect.height * geometry.size.height
        
        // Bounding Box
        RoundedRectangle(cornerRadius: 5)
            .stroke(Color.orange, lineWidth: 2) // Changed color for visibility
            .frame(width: w, height: h)
            .position(x: x + w / 2, y: y + h / 2) // Position center of the box
        
        // Label Text Background
        Text("\(detection.label) \(String(format: "%.0f%%", detection.confidence * 100))")
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .background(Color.orange.opacity(0.8))
            .cornerRadius(4)
        // Position label just above the top-left corner of the box
            .position(x: x + w / 2, y: y - 10) // Adjust y offset as needed
    }
    
    // Displays error messages
    @ViewBuilder
    private func errorOverlay(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.yellow)
                .cornerRadius(5)
                .padding(.bottom, 80) // Position above the picker
        }
        .frame(maxWidth: .infinity)
    }
    
    // Creates the model selection picker
    @ViewBuilder
    private func modelPicker() -> some View {
        Picker("Select Model", selection: $vm.selectedModel) {
            ForEach(YOLOModel.allCases) { model in
                Text(model.displayName).tag(model)
            }
        }
        .pickerStyle(.segmented) // Or .menu for more items
        .background(Color.black.opacity(0.5)) // Make background visible
        .cornerRadius(8)
        .padding(.horizontal, 20) // Add horizontal padding
        // Ensure the picker itself uses a color scheme that's visible
        .colorScheme(.dark) // Makes the default segmented picker text/selection white
    }
}

// MARK: - SwiftUI Previews

#Preview("YOLOv3CameraView_Preview") { // Use the new struct name
    YOLOv3CameraView_V3()
}

// MARK: - App Entry Point (Optional)
/*
 @main
 struct YOLOv3CameraApp: App {
 var body: some Scene {
 WindowGroup {
 YOLOv3CameraView_V3() // Use the new struct name
 }
 }
 }
 */
