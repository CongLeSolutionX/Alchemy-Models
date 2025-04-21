////
////  YOLOv3CameraView_V3.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//import SwiftUI
//import AVFoundation
//import Vision
//import CoreML
//import UIKit
//
//// MARK: – Detection Model
//
//struct Detection: Identifiable {
//    let id = UUID()
//    let boundingBox: CGRect   // normalized (0…1)
//    let label: String
//    let confidence: VNConfidence
//}
//
//// MARK: – Camera + Vision Coordinator
//
//class CameraViewModel: NSObject, ObservableObject {
//    @Published var detections: [Detection] = []
//    let session = AVCaptureSession()
//    
//    private var visionRequest: VNCoreMLRequest?
//    
//    override init() {
//        super.init()
//        configureModel()
//        configureSession()
//    }
//    
//    private func configureModel() {
//        // Load the compiled YOLOv3.mlmodelc from your bundle
//        guard let model = try? yolo11n(configuration: .init()).model,
//              let vnModel = try? VNCoreMLModel(for: model)
//        else {
//            print("❌ Failed to load YOLOv3")
//            return
//        }
//        
//        let req = VNCoreMLRequest(model: vnModel, completionHandler: handleDetections)
//        req.imageCropAndScaleOption = .scaleFill
//        visionRequest = req
//    }
//    
//    private func configureSession() {
//        session.beginConfiguration()
//        session.sessionPreset = .high
//        
//        // 1) Camera input
//        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                                   for: .video,
//                                                   position: .back),
//              let input = try? AVCaptureDeviceInput(device: device)
//        else {
//            print("❌ Cannot access camera")
//            session.commitConfiguration()
//            return
//        }
//        session.addInput(input)
//        
//        // 2) Video output
//        let output = AVCaptureVideoDataOutput()
//        output.videoSettings = [
//            kCVPixelBufferPixelFormatTypeKey as String:
//                kCVPixelFormatType_32BGRA
//        ]
//        output.setSampleBufferDelegate(self,
//                                       queue: DispatchQueue(label: "videoQueue"))
//        session.addOutput(output)
//        
//        session.commitConfiguration()
//    }
//    
//    // MARK: – Start / Stop (off main thread)
//    
//    func start() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.session.startRunning()
//        }
//    }
//    
//    func stop() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.session.stopRunning()
//        }
//    }
//    
//    // MARK: – Handle Vision Results
//    
//    private func handleDetections(request: VNRequest, error: Error?) {
//        guard let observations = request.results as? [VNRecognizedObjectObservation]
//        else { return }
//        
//        let dets = observations.compactMap { obs -> Detection? in
//            guard let top = obs.labels.first else { return nil }
//            return Detection(boundingBox: obs.boundingBox,
//                             label: top.identifier,
//                             confidence: top.confidence)
//        }
//        
//        DispatchQueue.main.async {
//            self.detections = dets
//        }
//    }
//}
//
//extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput,
//                       didOutput sampleBuffer: CMSampleBuffer,
//                       from connection: AVCaptureConnection)
//    {
//        guard let req = visionRequest,
//              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        else { return }
//        
//        let handler = VNImageRequestHandler(
//            cvPixelBuffer: pixelBuffer,
//            orientation: .up,
//            options: [:]
//        )
//        
//        try? handler.perform([req])
//    }
//}
//
//// MARK: – UIKit Preview Layer Wrapper
//
///// A UIView whose backing layer is AVCaptureVideoPreviewLayer
//fileprivate class PreviewView: UIView {
//    override class var layerClass: AnyClass {
//        AVCaptureVideoPreviewLayer.self
//    }
//    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
//        layer as! AVCaptureVideoPreviewLayer
//    }
//}
//
//#Preview("PreviewView") {
//    PreviewView()
//}
//
///// SwiftUI wrapper for PreviewView
//fileprivate struct CameraPreview: UIViewRepresentable {
//    let session: AVCaptureSession
//    
//    func makeUIView(context: Context) -> PreviewView {
//        let view = PreviewView()
//        let pl  = view.videoPreviewLayer
//        pl.session      = session
//        pl.videoGravity = .resizeAspectFill
//        
//        // >>> Replace deprecated videoOrientation with videoRotationAngle
//        if let conn = pl.connection {
//            if #available(iOS 17.0, *) {
//                // 0° = portrait, 90 = .landscapeRight, 180 = .portraitUpsideDown, 270 = .landscapeLeft
//                conn.videoRotationAngle = 90
//            } else {
//                conn.videoOrientation = .portrait
//            }
//        }
//        
//        return view
//    }
//    
//    func updateUIView(_ uiView: PreviewView, context: Context) {
//        // Nothing to do—layerClass handles sizing & layout
//    }
//}
//
//// MARK: – Main SwiftUI View
//
//struct YOLOv3CameraView: View {
//    @StateObject private var vm = CameraViewModel()
//    
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                // Live camera feed
//                CameraPreview(session: vm.session)
//                    .ignoresSafeArea()
//                
//                // Bounding boxes + labels
//                ForEach(vm.detections) { det in
//                    let rect = det.boundingBox
//                    let x = rect.minX * geo.size.width
//                    let y = (1 - rect.minY - rect.height) * geo.size.height
//                    let w = rect.width * geo.size.width
//                    let h = rect.height * geo.size.height
//                    
//                    // Box
//                    RoundedRectangle(cornerRadius: 4)
//                        .stroke(Color.red, lineWidth: 2)
//                        .frame(width: w, height: h)
//                        .position(x: x + w/2, y: y + h/2)
//                    
//                    // Label
//                    Text("\(det.label) \(Int(det.confidence * 100))%")
//                        .font(.caption2.bold())
//                        .foregroundColor(.white)
//                        .padding(4)
//                        .background(Color.red.opacity(0.7))
//                        .cornerRadius(4)
//                        .position(x: x + 4 + (w - 8)/2, y: y + 12)
//                }
//            }
//            .onAppear { vm.start() }
//            .onDisappear { vm.stop() }
//        }
//    }
//}
//
//#Preview("YOLOv3CameraView") {
//    YOLOv3CameraView()
//}
//
//// MARK: – App Entry Point
////
////@main
////struct YOLOv3CameraApp: App {
////  var body: some Scene {
////    WindowGroup {
////      YOLOv3CameraView()
////    }
////  }
////}
