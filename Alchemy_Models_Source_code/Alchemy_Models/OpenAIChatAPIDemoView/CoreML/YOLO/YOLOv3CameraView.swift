//
//  YOLOv3CameraView.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

// MARK: – Detection Model

struct Detection: Identifiable {
  let id = UUID()
  let boundingBox: CGRect   // normalized 0…1
  let label: String
  let confidence: VNConfidence
}

// MARK: – Camera + Vision Coordinator

class CameraViewModel: NSObject, ObservableObject {
  @Published var detections: [Detection] = []
  
  let previewLayer = AVCaptureVideoPreviewLayer()
  private let session = AVCaptureSession()
  private var visionRequest: VNCoreMLRequest?
  
  override init() {
    super.init()
    configureModel()
    configureSession()
  }
  
  private func configureModel() {
    guard let mlmodel = try? YOLOv3Tiny(configuration: MLModelConfiguration()).model,
          let vnmodel = try? VNCoreMLModel(for: mlmodel) else
    {
      print("❌ Failed to load YOLOv3Tiny")
      return
    }
    let req = VNCoreMLRequest(model: vnmodel, completionHandler: handleDetections)
    req.imageCropAndScaleOption = .scaleFill
    visionRequest = req
  }
  
  private func configureSession() {
    session.beginConfiguration()
    session.sessionPreset = .high
    
    // Camera input
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                               for: .video, position: .back),
          let input = try? AVCaptureDeviceInput(device: device)
    else {
      print("❌ Cannot access camera")
      return
    }
    session.addInput(input)
    
    // Video output
    let output = AVCaptureVideoDataOutput()
    output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
    output.videoSettings =
      [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    session.addOutput(output)
    
    // Preview layer
    previewLayer.session = session
    previewLayer.videoGravity = .resizeAspectFill
    
    session.commitConfiguration()
  }
  
  func start() { session.startRunning() }
  func stop()  { session.stopRunning() }
  
  private func handleDetections(request: VNRequest, error: Error?) {
    guard let results = request.results as? [VNRecognizedObjectObservation] else {
      return
    }
    // Map to our Detection struct, take only top label
    let dets = results.compactMap { obs -> Detection? in
      guard let top = obs.labels.first else { return nil }
      return Detection(
        boundingBox: obs.boundingBox,
        label: top.identifier,
        confidence: top.confidence
      )
    }
    DispatchQueue.main.async {
      self.detections = dets
    }
  }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection)
  {
    guard let req = visionRequest,
          let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }
    
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                        orientation: .up,
                                        options: [:])
    do {
      try handler.perform([req])
    } catch {
      print("Vision error:", error)
    }
  }
}

// MARK: – SwiftUI Preview Layer

struct CameraPreview: UIViewRepresentable {
  let previewLayer: AVCaptureVideoPreviewLayer
  
  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    previewLayer.frame = view.bounds
    view.layer.addSublayer(previewLayer)
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    previewLayer.frame = uiView.bounds
  }
}

// MARK: – Main SwiftUI View

struct YOLOv3CameraView: View {
  @StateObject private var vm = CameraViewModel()
  
  var body: some View {
    GeometryReader { geo in
      ZStack {
        // 1) Camera preview
        CameraPreview(previewLayer: vm.previewLayer)
          .ignoresSafeArea()
        
        // 2) Overlays
        ForEach(vm.detections) { det in
          // Convert Vision's normalized rect to view coords
          let x = det.boundingBox.minX * geo.size.width
          let w = det.boundingBox.width * geo.size.width
          // Vision’s y=0 is bottom, SwiftUI’s y=0 is top
          let y = (1 - det.boundingBox.minY - det.boundingBox.height) * geo.size.height
          let h = det.boundingBox.height * geo.size.height
          
          // Bounding box
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color.red, lineWidth: 2)
            .frame(width: w, height: h)
            .position(x: x + w/2, y: y + h/2)
          
          // Label + confidence
          Text("\(det.label) \(Int(det.confidence * 100))%")
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(4)
            .background(Color.red.opacity(0.7))
            .cornerRadius(4)
            .position(x: x + 4 + (w - 8) * 0.5,
                      y: y + 10)
        }
      }
      .onAppear { vm.start() }
      .onDisappear { vm.stop() }
    }
  }
}

// MARK: – Preview
//
//#Preview {
//  YOLOv3CameraView()
//}
