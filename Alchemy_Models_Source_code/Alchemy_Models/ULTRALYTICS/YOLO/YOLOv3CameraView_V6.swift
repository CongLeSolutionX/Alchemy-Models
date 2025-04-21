//
//  YOLOv3CameraView_V6.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/21/25.
//


import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine

// MARK: — Detection Model (No changes needed)

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect   // normalized (0…1)
    let label: String
    let confidence: VNConfidence
}

// MARK: — Available YOLO Models (Updated for v8 and v11 Detection)

enum YOLOModel: String, CaseIterable, Identifiable {
    // --- YOLOv8 Detection Models ---
    case yolov8l = "yolov8l"
    case yolov8m = "yolov8m"
    case yolov8n = "yolov8n"
    case yolov8s = "yolov8s"
    case yolov8x = "yolov8x"
    
    // --- YOLOv11 Detection Models ---
    case yolo11l = "yolo11l"
    case yolo11m = "yolo11m"
    case yolo11n = "yolo11n"
    case yolo11s = "yolo11s"
    case yolo11x = "yolo11x"
    
    // --- Identifiable Conformance ---
    var id: String { rawValue }
    
    // --- Display Name for Picker ---
    var displayName: String {
        switch self {
            // v8
        case .yolov8l: return "YOLOv8-L"
        case .yolov8m: return "YOLOv8-M"
        case .yolov8n: return "YOLOv8-N"
        case .yolov8s: return "YOLOv8-S"
        case .yolov8x: return "YOLOv8-X"
            // v11
        case .yolo11l: return "YOLOv11-L"
        case .yolo11m: return "YOLOv11-M"
        case .yolo11n: return "YOLOv11-N"
        case .yolo11s: return "YOLOv11-S"
        case .yolo11x: return "YOLOv11-X"
        }
    }
    
    // --- Subdirectory based on Image Structure ---
    var subdirectory: String {
        switch self {
        case .yolov8l, .yolov8m, .yolov8n, .yolov8s, .yolov8x:
            return "DetectModels/yolov8_coreml_models" // Path from image
        case .yolo11l, .yolo11m, .yolo11n, .yolo11s, .yolo11x:
            return "DetectModels/yolov11_coreml_models" // Path from image
        }
    }
    
    // --- Updated loadModel Implementation with Subdirectory ---
    func loadModel() async -> MLModel? {
        // 1. Get the base name (same as the .mlpackage file name)
        let modelFileName = self.rawValue // e.g., "yolov8n"
        
        // 2. Construct the full path within the bundle including the subdirectory
        let resourcePath = "\(self.subdirectory)/\(modelFileName)" // e.g., "DetectModels/yolov8_coreml_models/yolov8n"
        
        // 3. Find the URL for the compiled model (.mlmodelc) using the full path
        guard let modelURL = Bundle.main.url(forResource: resourcePath,
                                             withExtension: "mlmodelc") else {
            print("❌ Error: Failed to find compiled model at '\(resourcePath).mlmodelc' in the bundle.")
            // Common Reasons:
            // - Typo in subdirectory or modelFileName.
            // - .mlpackage file not added to "Copy Bundle Resources" in Build Phases.
            // - .mlpackage failed to compile during build. Check build logs.
            // - Folder structure in Xcode project doesn't EXACTLY match the string paths used here.
            return nil
        }
        
        // 4. Load the MLModel from the URL
        do {
            let configuration = MLModelConfiguration()
            // Optional: Configure compute units
            // configuration.computeUnits = .all
            
            let loadedModel = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
            print("✅ Successfully loaded model \(modelFileName) from URL: \(modelURL.path)")
            return loadedModel
        } catch {
            print("❌ Error: Failed to load model '\(modelFileName)' from URL \(modelURL): \(error)")
            return nil
        }
    }
}

// MARK: — Camera + Vision ViewModel (Minor change in default selection)

@MainActor // Recommended for ViewModels interacting heavily with UI
class CameraViewModel: NSObject, ObservableObject {
    // Published for UI
    @Published var detections: [Detection] = []
    // --- Changed default model to yolov8n as an example ---
    @Published var selectedModel: YOLOModel = .yolov8n
    @Published var confidenceThreshold: Double = 0.3
    @Published var showBoxes: Bool = true
    @Published var isSessionRunning: Bool = false
    @Published var modelLoadError: String? = nil
    @Published var fps: Double = 0
    
    let session = AVCaptureSession()
    private var visionRequest: VNCoreMLRequest?
    private var cancellables = Set<AnyCancellable>()
    
    // For FPS calculation
    private var lastTimestamp: CFTimeInterval = 0
    
    // Flag to prevent concurrent model loading
    private var isLoadingModel = false
    
    override init() {
        super.init()
        configureSession()
        bindModelSelection()
        // Trigger initial model load
        Task {
            await load(model: selectedModel)
        }
    }
    
    // MARK: Session Setup (No functional changes)
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high // Consider .hd1280x720 for potentially better perf
        
        // Camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            modelLoadError = "Unable to access camera"
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        
        // Video output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA // Ensure compatibility with Vision
        ]
        output.alwaysDiscardsLateVideoFrames = true // Important for real-time
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
        output.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            modelLoadError = "Could not add video data output"
            session.commitConfiguration()
            return
        }
        
        
        // >>> Replace deprecated videoOrientation with videoRotationAngle
        if let conn = output.connection(with: .video){
            if #available(iOS 17.0, *) {
                // 0° = portrait, 90 = .landscapeRight, 180 = .portraitUpsideDown, 270 = .landscapeLeft
                conn.videoRotationAngle = 90
            } else {
                conn.videoOrientation = .portrait
            }
        }
        
        session.commitConfiguration()
    }
    
    // MARK: Model Loading (Updated Sink logic for safety)
    
    private func bindModelSelection() {
        $selectedModel
            .removeDuplicates() // Avoid reloading the same model
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main) // Short debounce
            .sink { [weak self] newModel in
                guard let self = self else { return }
                // Start loading task
                Task {
                    await self.load(model: newModel)
                }
            }
            .store(in: &cancellables)
    }
    
    // Updated load function with loading flag
    private func load(model: YOLOModel) async {
        // Prevent concurrent loads
        guard !isLoadingModel else {
            print("⚠️ Model loading already in progress for \(model.displayName), skipping.")
            return
        }
        isLoadingModel = true
        defer { isLoadingModel = false } // Ensure flag is reset
        
        // Clear previous errors/detections on main thread
        self.modelLoadError = nil
        self.detections = []
        print("🔄 Starting load for model: \(model.displayName)...")
        
        // Load MLModel (can take time, keep off main thread)
        guard let loadedMLModel = await model.loadModel() else {
            self.modelLoadError = "Failed to load \(model.displayName) MLModel"
            print("❌ Failed to load \(model.displayName) MLModel")
            self.visionRequest = nil // Clear vision request
            return
        }
        
        // Create VNCoreMLModel (relatively fast)
        guard let vnModel = try? VNCoreMLModel(for: loadedMLModel) else {
            self.modelLoadError = "Failed to create VNCoreMLModel for \(model.displayName)"
            print("❌ Failed to create VNCoreMLModel for \(model.displayName)")
            self.visionRequest = nil // Clear vision request
            return
        }
        
        // Create the request (quick)
        let request = VNCoreMLRequest(model: vnModel, completionHandler: handleDetections)
        request.imageCropAndScaleOption = .scaleFill // Common choice, adjust if needed
        
        // --- Set confidence directly on the request if available (iOS 17+) ---
        //       if #available(iOS 17.0, *) {
        //           // Bind the published confidence threshold directly
        //           // Note: This requires the ViewModel to be @MainActor or careful thread handling
        //           request.confidence = VNConfidence(self.confidenceThreshold)
        //           // We'll also need to update this when the slider changes if we use this approach.
        //           // For simplicity with the current structure, we'll keep filtering in handleDetections.
        //       }
        
        // Update the visionRequest property
        self.visionRequest = request
        print("✅ Successfully created Vision request for \(model.displayName)")
    }
    
    // MARK: Start / Stop (No changes needed)
    
    func toggleSession() {
        if session.isRunning { stop() }
        else { start() }
    }
    
    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async { // Switch back to main thread for UI update
                self?.isSessionRunning = true
            }
        }
    }
    
    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { // Switch back to main thread for UI update
                self?.isSessionRunning = false
                // Clear detections when stopping
                self?.detections = []
                self?.fps = 0
            }
        }
    }
    
    // MARK: Handling Vision Results (Threshold filtering remains here for broader iOS support)
    
    private func handleDetections(request: VNRequest, error: Error?) {
        // Always check for errors first
        if let visionError = error {
            // Use DispatchQueue.main.async if not already on the main actor
            self.modelLoadError = "Vision Error: \(visionError.localizedDescription)"
            self.detections = [] // Clear detections on error
            print("❌ Vision processing error: \(visionError)")
            return
        }
        
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            // This might happen if the loaded model isn't an object detector
            // or if there are simply no detections.
            self.detections = [] // Clear previous detections
            // Optional: print a warning if you expect observations
            // print("⚠️ Received no observations or observations are not VNRecognizedObjectObservation.")
            return
        }
        
        // Filter by confidence threshold
        // Doing filtering here works across all iOS versions easily
        let filtered: [Detection] = observations.compactMap { obs in
            guard let topLabel = obs.labels.first, // Get the label with the highest confidence
                  topLabel.confidence >= VNConfidence(self.confidenceThreshold) // Compare with threshold
            else { return nil }
            
            // Create Detection object
            return Detection(boundingBox: obs.boundingBox,
                             label: topLabel.identifier,
                             confidence: topLabel.confidence)
            
        }
        
        // Calculate FPS (moved calculation off main thread slightly)
        let now = CACurrentMediaTime()
        let currentFPS = lastTimestamp > 0 ? 1.0 / (now - lastTimestamp) : 0
        // Update timestamp immediately for next frame calculation
        lastTimestamp = now
        
        // Publish updates back on the main thread (if not already guaranteed by @MainActor)
        // DispatchQueue.main.async { // Removed if using @MainActor
        self.fps = currentFPS
        self.detections = filtered
        // Clear error message if we successfully get results (even if empty)
        if self.modelLoadError != nil && error == nil {
            self.modelLoadError = nil
        }
        // } // Removed if using @MainActor
    }
}
// MARK: — AVCapture Delegate

extension CameraViewModel: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        guard let req = visionRequest,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        // Pass the buffer into the Vision handler
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])
        try? handler.perform([req])
    }
}

//// MARK: — AVCapture Delegate (No changes needed)
//
//extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
//    nonisolated func captureOutput(_ output: AVCaptureOutput,
//                                   didOutput sampleBuffer: CMSampleBuffer,
//                                   from connection: AVCaptureConnection)
//    {
//        // Ensure session is running and we have a request
//        guard isSessionRunning, let req = visionRequest else { return }
//        
//        // Get pixel buffer
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            print("⚠️ Could not get pixel buffer from sample buffer")
//            return
//        }
//        
//        // Create Handler and Perform Request
//        // The orientation is based on the CVPixelBuffer itself,
//        // assuming the camera and connection setup handle rotation correctly.
//        // If boxes are misaligned, revisit the connection's videoRotationAngle.
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
//                                            // Orientation: Use .up assumes buffer is correctly oriented by capture settings
//                                            // If coordinates are wrong, try experiment with e.g. .right
//                                            orientation: .up,
//                                            options: [:])
//        do {
//            try handler.perform([req])
//        } catch {
//            // Handle potential errors during Vision processing
//            print("❌ Failed to perform Vision request: \(error)")
//            // Update UI with error on main thread if needed
//            DispatchQueue.main.async { [weak self] in
//                self?.modelLoadError = "Vision Processing Failed: \(error.localizedDescription)"
//            }
//        }
//    }
//}

// MARK: — Preview Layer Wrapper (Updated Rotation Handling)

fileprivate class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

fileprivate struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let pl = view.previewLayer
        pl.session = session
        pl.videoGravity = .resizeAspectFill
        
        // --- Ensure Preview Rotation matches Output Rotation ---
        if let conn = pl.connection {
            if #available(iOS 17.0, *) {
                // 0° = portrait, 90 = .landscapeRight, 180 = .portraitUpsideDown, 270 = .landscapeLeft
                conn.videoRotationAngle = 90
            } else {
                conn.videoOrientation = .portrait
            }
        } else {
            print("⚠️ Preview layer connection unavailable for setting rotation.")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

// MARK: — Main SwiftUI View (No significant changes needed, Picker updates automatically)

struct YOLOCameraView: View {
    // Use @StateObject for owning the ViewModel instance
    @StateObject private var vm = CameraViewModel()
    
    
    var body: some View {
        CameraPreview(session: vm.session)
            .ignoresSafeArea()
    }
    //    var body: some View {
    //        // Use NavigationView for the toolbar
    //        NavigationView {
    //            ZStack {
    //                 // --- Camera Preview Background ---
    //                 CameraPreview(session: vm.session)
    //                     .ignoresSafeArea()
    //
    //                 // --- Bounding Box Overlay ---
    //                 if vm.showBoxes {
    //                     GeometryReader { geo in
    //                         ForEach(vm.detections) { det in
    //                             detectionView(det, in: geo.size)
    //                         }
    //                     }
    //                 }
    //
    //                 // --- Top Info Bar (Model / Count / FPS) ---
    //                 VStack {
    //                     HStack(spacing: 12) {
    //                         // Display selected model's name
    //                         Text(vm.selectedModel.displayName)
    //                             .font(.caption.weight(.medium)) // Smaller font
    //                         Spacer()
    //                         Text("Det: \(vm.detections.count)")
    //                              .font(.caption.weight(.medium))
    //                         Spacer()
    //                         Text(String(format: "FPS: %.1f", vm.fps))
    //                              .font(.caption.weight(.medium))
    //                     }
    //                     .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)) // Tighter padding
    //                     .background(Color.black.opacity(0.65))
    //                     .foregroundColor(.white)
    //                     .cornerRadius(8)
    //                     .padding(.horizontal) // Padding from screen edges remains
    //                     .padding(.top, 8) // Padding from top safe area
    //                     Spacer() // Pushes info bar to the top
    //                 }
    //
    //                // MARK: — Bottom Controls
    //                VStack(spacing: 10) { // Reduced spacing
    //                    Spacer() // Pushes controls to the bottom
    //
    //                    // Confidence Slider
    //                    HStack {
    //                        Text("Thresh: \(Int(vm.confidenceThreshold * 100))%")
    //                             .font(.caption) // Smaller font
    //                             .frame(width: 80, alignment: .leading) // Fixed width for alignment
    //                        Slider(value: $vm.confidenceThreshold, in: 0...1, step: 0.01)
    //                              // Consider adding onChange to update request immediately if using iOS 17+ minimumConfidence
    //                              // .onChange(of: vm.confidenceThreshold) { newValue in
    //                              //      vm.updateRequestConfidence(to: newValue) // Need to implement this func
    //                              // }
    //                    }
    //                     .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
    //                     .background(Color.black.opacity(0.65))
    //                     .foregroundColor(.white)
    //                     .cornerRadius(8)
    //                     .padding(.horizontal)
    //
    //                    // Model Picker
    //                    Picker("Select Model", selection: $vm.selectedModel) {
    //                         // Iterate through all defined models
    //                         ForEach(YOLOModel.allCases) { model in
    //                             Text(model.displayName).tag(model)
    //                         }
    //                    }
    //                     .pickerStyle(.segmented) // Good choice for limited options
    //                     .padding(.horizontal)
    //                     .background( // Add background to picker itself for better visibility
    //                         Color.black.opacity(0.5)
    //                             .blur(radius: 3.0) // Optional blur effect
    //                     )
    //                     .cornerRadius(8) // Corner radius for the picker background
    //
    //                } // VStack
    //                 .padding(.bottom, 20) // Padding from bottom safe area
    //
    //                // MARK: — Error Banner
    //                if let err = vm.modelLoadError {
    //                    VStack {
    //                        Spacer() // Pushes banner towards bottom
    //                        Text(err)
    //                            .font(.caption) // Smaller font
    //                            .padding(8)
    //                            .frame(maxWidth: .infinity) // Span width
    //                            .background(Color.red.opacity(0.85))
    //                            .foregroundColor(.white)
    //                            .cornerRadius(6)
    //                            .padding(.horizontal) // Padding from screen edges
    //                            .padding(.bottom, 80) // Position above bottom controls
    //                             .transition(.move(edge: .bottom).combined(with: .opacity)) // Add animation
    //                             .zIndex(1) // Ensure it's above other elements if needed
    //                         .onTapGesture {
    //                              withAnimation {
    //                                   vm.modelLoadError = nil // Allow dismissing by tapping
    //                               }
    //                         }
    //                    }
    //                }
    //            }
    //             .navigationBarTitle("YOLO Detection", displayMode: .inline)
    //             .navigationBarTitleDisplayMode(.inline) // Ensure inline title
    //             .toolbar {
    //                 // Left: Pause / Resume Button
    //                 ToolbarItem(placement: .navigationBarLeading) {
    //                     Button {
    //                         vm.toggleSession()
    //                     } label: {
    //                         Image(systemName: vm.isSessionRunning ? "pause.circle.fill" : "play.circle.fill")
    //                            .resizable()
    //                            .frame(width: 28, height: 28) // Slightly larger tap area
    //                             .foregroundColor(.white)
    //                     }
    //                 }
    //                 // Right: Toggle Boxes Button
    //                 ToolbarItem(placement: .navigationBarTrailing) {
    //                     Button {
    //                         vm.showBoxes.toggle()
    //                     } label: {
    //                          Image(systemName: vm.showBoxes ? "eye.fill" : "eye.slash.fill")
    //                            .resizable()
    //                            .frame(width: 28, height: 20) // Adjust size as needed
    //                             .foregroundColor(.white)
    //                     }
    //                 }
    //             }
    //             .toolbarBackground(.black.opacity(0.50), for: .navigationBar) // Make toolbar semi-transparent
    //             .toolbarBackground(.visible, for: .navigationBar) // Ensure background is visible
    //             .preferredColorScheme(.dark) // Force dark scheme for better contrast
    //
    //            // Start session when view appears
    //            .onAppear {
    //                 // Ensure model loads if not already loaded
    //                 if vm.visionRequest == nil && !vm.isLoadingModel {
    //                      Task {
    //                         await vm.load(model: vm.selectedModel)
    //                       }
    //                 }
    //                 vm.start()
    //             }
    //
    //            // Stop session when view disappears
    //            .onDisappear { vm.stop() }
    //        }
    //        .statusBarHidden(true) // Hide status bar for full screen immersion
    //    }
    
    // MARK: — Single Detection View (Optimized drawing)
    @ViewBuilder
    private func detectionView(_ det: Detection, in size: CGSize) -> some View {
        // --- Calculate Correct Frame based on Normalized Coordinates ---
        // Note: Y coordinate is inverted in Vision (0 is top), but SwiftUI's origin is top-left.
        // The previous calculation was correct for direct mapping if origin aligns.
        // Check if boundingBox origin needs adjustment depending on Vision/CoreML output specifics.
        // Usually: (minX, minY) is top-left in normalized Vison space.
        // SwiftUI: origin is top-left.
        let x = det.boundingBox.minX * size.width
        let y = det.boundingBox.minY * size.height // Use minY for top edge
        let w = det.boundingBox.width * size.width
        let h = det.boundingBox.height * size.height
        
        let ConfidenceLabel = "\(det.label) \(Int(det.confidence * 100))%"
        let color = Color.orange // Or assign colors based on label
        
        // Use ZStack for layering Box and Text efficiently
        ZStack(alignment: .topLeading) {
            // Box Rectangle
            Rectangle() // Use standard Rectangle for performance if corner radius isn't critical
                .stroke(color, lineWidth: 2)
                .frame(width: w, height: h)
            // Position the ZStack itself, contains both box and text
                .position(x: x + w / 2, y: y + h / 2)
            
            // Confidence Text Label
            Text(ConfidenceLabel)
                .font(.caption2.bold())
                .padding(.horizontal, 4)
                .padding(.vertical, 2) // Add vertical padding
                .background(color.opacity(0.8)) // Use color from box
                .foregroundColor(.white)
                .cornerRadius(4)
            // Position text slightly above the top-left corner of the ZStack's coordinate space
            // (relative to the ZStack's frame positioned by .position above)
            // Adjust offset carefully for precise placement if needed.
                .offset(x: x, y: y - 20) // Position based on top-left box corner
        }
    }
}

// MARK: — SwiftUI Preview

struct YOLOCameraView_Previews: PreviewProvider {
    static var previews: some View {
        YOLOCameraView()
            .edgesIgnoringSafeArea(.all) // Ensure preview ignores safe area like the main view
            .preferredColorScheme(.dark) // Match preview to app appearance
    }
}
