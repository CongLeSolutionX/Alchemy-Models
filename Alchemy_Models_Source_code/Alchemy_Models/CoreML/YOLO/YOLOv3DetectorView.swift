////
////  YOLOv3DetectorView.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
//import SwiftUI
//import Vision
//import CoreML
//import UIKit
//
///// A single SwiftUI view that
///// • Picks an image from your Photo Library
///// • Runs a VNCoreMLRequest backed by YOLOv3
///// • Draws detected boxes + labels on the image
//struct YOLOv3DetectorView: View {
//    // MARK: State
//    @State private var image: UIImage?              // chosen image
//    @State private var detections: [Detection] = [] // results
//    @State private var showingPicker = false
//    @State private var isDetecting = false
//    
//    // Load Vision model once
//    private let vnModel: VNCoreMLModel? = {
//        do {
//            let config = MLModelConfiguration()
//            let coreMLmodel = try YOLOv3Tiny(configuration: config).model
//            return try VNCoreMLModel(for: coreMLmodel)
//        } catch {
//            print("❌ Failed to load YOLOv3: \(error)")
//            return nil
//        }
//    }()
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//                // MARK: – Image + overlay
//                ZStack {
//                    if let uiImage = image {
//                        GeometryReader { geo in
//                            Image(uiImage: uiImage)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                .overlay {
//                                    // draw each detection
//                                    ForEach(detections) { det in
//                                        let bb = det.boundingBox
//                                        // convert normalized (0–1) boundingBox to view coords
//                                        let x = bb.minX * geo.size.width
//                                        let w = bb.width * geo.size.width
//                                        let y = (1 - bb.minY - bb.height) * geo.size.height
//                                        let h = bb.height * geo.size.height
//                                        
//                                        RoundedRectangle(cornerRadius: 4)
//                                            .stroke(Color.red, lineWidth: 2)
//                                            .frame(width: w, height: h)
//                                            .position(x: x + w/2, y: y + h/2)
//                                        
//                                        Text("\(det.label) \(Int(det.confidence*100))%")
//                                            .font(.caption2).bold()
//                                            .foregroundColor(.white)
//                                            .padding(4)
//                                            .background(Color.red.opacity(0.7))
//                                            .cornerRadius(4)
//                                            .position(x: x + 4 + (w - 8)*0.5, // shift inside box
//                                                      y: y + 10)
//                                    }
//                                }
//                        }
//                    } else {
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color.gray.opacity(0.2))
//                            .overlay(Text("Tap “Select Image”").foregroundColor(.secondary))
//                    }
//                }
//                .frame(height: 300)
//                .clipped()
//                
//                // MARK: – Status / spinner
//                if isDetecting {
//                    ProgressView("Detecting…")
//                }
//                
//                Spacer()
//                
//                // MARK: – Controls
//                HStack {
//                    Button("Select Image") {
//                        showingPicker = true
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .disabled(isDetecting)
//                    
//                    Button("Clear") {
//                        image = nil
//                        detections = []
//                    }
//                    .buttonStyle(.bordered)
//                    .disabled(isDetecting || image == nil)
//                }
//            }
//            .padding()
//            .navigationTitle("YOLOv3 Detector")
//            .sheet(isPresented: $showingPicker) {
//                ImagePicker { uiImage in
//                    showingPicker = false
//                    guard let uiImage = uiImage else { return }
//                    image = uiImage
//                    detections = []
//                    classify(uiImage)
//                }
//            }
//        }
//    }
//    
//    /// Run Vision+CoreML request
//    private func classify(_ uiImage: UIImage) {
//        guard let model = vnModel,
//              let cgImage = uiImage.cgImage else {
//            return
//        }
//        isDetecting = true
//        
//        let request = VNCoreMLRequest(model: model) { req, err in
//            defer { isDetecting = false }
//            
//            if let err = err {
//                print("Vision error:", err)
//                return
//            }
//            
//            // parse results as VNRecognizedObjectObservation
//            let results = (req.results as? [VNRecognizedObjectObservation]) ?? []
//            detections = results.map {
//                // take top label
//                let top = $0.labels.first!
//                return Detection(boundingBox: $0.boundingBox,
//                                 label: top.identifier,
//                                 confidence: top.confidence)
//            }
//        }
//        request.imageCropAndScaleOption = .scaleFill
//        
//        let handler = VNImageRequestHandler(
//            cgImage: cgImage,
//            orientation: uiImage.cgImageOrientation,
//            options: [:]
//        )
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Handler failed:", error)
//                DispatchQueue.main.async { isDetecting = false }
//            }
//        }
//    }
//}
//
//// MARK: – Detection Model
//
///// Simple struct to hold each detection
//struct Detection: Identifiable {
//    let id = UUID()
//    let boundingBox: CGRect   // normalized 0–1
//    let label: String
//    let confidence: VNConfidence
//}
//
//// MARK: – UIImage ↔ Orientation
//
//fileprivate extension UIImage {
//    var cgImageOrientation: CGImagePropertyOrientation {
//        switch imageOrientation {
//            case .up: return .up
//            case .down: return .down
//            case .left: return .left
//            case .right: return .right
//            case .upMirrored: return .upMirrored
//            case .downMirrored: return .downMirrored
//            case .leftMirrored: return .leftMirrored
//            case .rightMirrored: return .rightMirrored
//            @unknown default: return .up
//        }
//    }
//}
//
//// MARK: – Image Picker Bridge
//
//fileprivate struct ImagePicker: UIViewControllerRepresentable {
//    var onPick: (UIImage?) -> Void
//    
//    func makeCoordinator() -> Coordinator { Coordinator(onPick) }
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = .photoLibrary
//        return picker
//    }
//    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
//    
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let onPick: (UIImage?) -> Void
//        init(_ onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }
//        
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            onPick(nil)
//        }
//        func imagePickerController(_ picker: UIImagePickerController,
//                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            let img = info[.originalImage] as? UIImage
//            onPick(img)
//        }
//    }
//}
//
//// MARK: – Preview
//
//#Preview {
//    YOLOv3DetectorView()
//}
