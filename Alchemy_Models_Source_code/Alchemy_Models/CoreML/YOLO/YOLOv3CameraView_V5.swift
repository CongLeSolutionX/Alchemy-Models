//
//  YOLOv3CameraView_V5.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/21/25.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine

// MARK: — Detection Model

struct Detection: Identifiable {
    let id = UUID()
    let boundingBox: CGRect   // normalized (0…1)
    let label: String
    let confidence: VNConfidence
}

// MARK: — Available YOLO Models

enum YOLOModel: String, CaseIterable, Identifiable {
    case yolo11l, yolo11m, yolo11n, yolo11s, yolo11x
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .yolo11l: return "YOLO11‑L"
        case .yolo11m: return "YOLO11‑M"
        case .yolo11n: return "YOLO11‑N"
        case .yolo11s: return "YOLO11‑S"
        case .yolo11x: return "YOLO11‑XL"
        }
    }
    func loadModel() -> MLModel? {
        // Xcode generates classes matching the mlpackage name
        switch self {
        case .yolo11l: return try? yolo11l(configuration: .init()).model
        case .yolo11m: return try? yolo11m(configuration: .init()).model
        case .yolo11n: return try? yolo11n(configuration: .init()).model
        case .yolo11s: return try? yolo11s(configuration: .init()).model
        case .yolo11x: return try? yolo11x(configuration: .init()).model
        }
    }
}

// MARK: — Camera + Vision ViewModel

class CameraViewModel: NSObject, ObservableObject {
    // Published for UI
    @Published var detections: [Detection] = []
    @Published var selectedModel: YOLOModel = .yolo11n
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

    override init() {
        super.init()
        configureSession()
        bindModelSelection()
    }

    // MARK: Session Setup

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

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
                kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self,
                                       queue: DispatchQueue(label: "videoQueue",
                                                            qos: .userInitiated))
        session.addOutput(output)

        // Lock orientation to portrait
        if let conn = output.connection(with: .video), conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }

        session.commitConfiguration()
    }

    // MARK: Model Loading

    private func bindModelSelection() {
        // Whenever selectedModel changes, reload the Vision request
        $selectedModel
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] model in
                self?.load(model: model)
            }
            .store(in: &cancellables)
    }

    private func load(model: YOLOModel) {
        DispatchQueue.main.async {
            self.modelLoadError = nil
            self.detections = []
        }

        guard let mlModel = model.loadModel(),
              let vnModel = try? VNCoreMLModel(for: mlModel)
        else {
            DispatchQueue.main.async {
                self.modelLoadError = "Failed to load \(model.rawValue)"
                self.visionRequest = nil
            }
            return
        }

        let request = VNCoreMLRequest(model: vnModel, completionHandler: handleDetections)
        request.imageCropAndScaleOption = .scaleFill
        visionRequest = request
    }

    // MARK: Start / Stop

    func toggleSession() {
        if session.isRunning { stop() }
        else { start() }
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isSessionRunning = true }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
            DispatchQueue.main.async { self.isSessionRunning = false }
        }
    }

    // MARK: Handling Vision Results

    private func handleDetections(request: VNRequest, error: Error?) {
        if let err = error {
            DispatchQueue.main.async {
                self.modelLoadError = "Vision Error: \(err.localizedDescription)"
            }
            return
        }

        guard let observations = request.results as? [VNRecognizedObjectObservation]
        else {
            // Wrong output type
            DispatchQueue.main.async {
                self.detections = []
            }
            return
        }

        // Filter by confidence threshold
        let filtered: [Detection] = observations.compactMap { obs in
            guard let label = obs.labels.first,
                  Double(label.confidence) >= self.confidenceThreshold
            else { return nil }
            return Detection(boundingBox: obs.boundingBox,
                             label: label.identifier,
                             confidence: label.confidence)
        }

        // Compute FPS
        let now = CACurrentMediaTime()
        let currentFPS = lastTimestamp > 0 ? 1 / (now - lastTimestamp) : 0
        lastTimestamp = now

        // Publish updates
        DispatchQueue.main.async {
            self.fps = currentFPS
            self.detections = filtered
            if !filtered.isEmpty {
                self.modelLoadError = nil
            }
        }
    }
}

// MARK: — AVCapture Delegate

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
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

// MARK: — Preview Layer Wrapper

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
        if let conn = pl.connection, conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

// MARK: — Main SwiftUI View

struct YOLOCameraView: View {
    @StateObject private var vm = CameraViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                CameraPreview(session: vm.session)
                    .ignoresSafeArea()

                // MARK: — Detections Overlay
                if vm.showBoxes {
                    GeometryReader { geo in
                        ForEach(vm.detections) { det in
                            detectionView(det, in: geo.size)
                        }
                    }
                }

                // MARK: — Top Info (Model / Count / FPS)
                VStack {
                    HStack(spacing: 12) {
                        Text(vm.selectedModel.displayName)
                        Spacer()
                        Text("Det: \(vm.detections.count)")
                        Spacer()
                        Text(String(format: "FPS: %.1f", vm.fps))
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .top])
                    Spacer()
                }

                // MARK: — Bottom Controls
                VStack(spacing: 12) {
                    Spacer()

                    // Confidence Slider
                    HStack {
                        Text("Thresh: \(Int(vm.confidenceThreshold * 100))%")
                        Slider(value: $vm.confidenceThreshold,
                               in: 0...1,
                               step: 0.01)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                    // Model Picker
                    Picker("", selection: $vm.selectedModel) {
                        ForEach(YOLOModel.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                } // VStack
                .padding(.bottom, 20)

                // MARK: — Error Banner
                if let err = vm.modelLoadError {
                    VStack {
                        Spacer()
                        Text(err)
                            .font(.caption2)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .padding(.bottom, 100)
                    }
                }
            }
            .toolbar {
                // Left: Pause / Resume
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.toggleSession()
                    } label: {
                        Image(systemName: vm.isSessionRunning
                              ? "pause.circle.fill"
                              : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                // Right: Toggle Boxes
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.showBoxes.toggle()
                    } label: {
                        Image(systemName: vm.showBoxes
                              ? "eye.fill"
                              : "eye.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationBarTitle("YOLO Detection", displayMode: .inline)
            .onAppear { vm.start() }
            .onDisappear { vm.stop() }
        }
        .statusBarHidden(true)
    }

    // MARK: — Single Detection View
    @ViewBuilder
    private func detectionView(_ det: Detection, in size: CGSize) -> some View {
        let x = det.boundingBox.minX * size.width
        let y = (1 - det.boundingBox.maxY) * size.height
        let w = det.boundingBox.width * size.width
        let h = det.boundingBox.height * size.height

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: w, height: h)
                .position(x: x + w/2, y: y + h/2)

            Text("\(det.label) \(Int(det.confidence * 100))%")
                .font(.caption2.bold())
                .padding(4)
                .background(Color.orange.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(4)
                .position(x: x + w/2, y: y - 10)
        }
    }
}

// MARK: — SwiftUI Preview

struct YOLOCameraView_Previews: PreviewProvider {
    static var previews: some View {
        YOLOCameraView()
            .edgesIgnoringSafeArea(.all)
    }
}
