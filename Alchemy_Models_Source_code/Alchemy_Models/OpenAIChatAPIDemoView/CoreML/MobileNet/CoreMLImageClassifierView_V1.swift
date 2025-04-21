////
////  CoreMLImageClassifierView.swift
////  Alchemy_Models
////
////  Created by Cong Le on 4/20/25.
////
//
////
////  CoreMLImageClassifierView.swift
////  Single‐File SwiftUI CoreML Demo
////
////  Drop a CoreML model named “MobileNetV2” (or update the class name below) into your project.
////  Requires: Xcode 15+, iOS 17+
////
//
//import SwiftUI
//import CoreML
//import Vision
//import UIKit
//
//struct CoreMLImageClassifierView: View {
//    @State private var image: UIImage?             // Selected image
//    @State private var classification: String = ""  // Model's output label
//    @State private var showingPicker = false       // Toggle image picker
//    @State private var isProcessing = false        // Busy indicator
//    
//    // Load VNCoreMLModel once
//    private let vnModel: VNCoreMLModel? = {
//        do {
//            // Replace `MobileNetV2` with your model's auto‐gen class name
//            let config = MLModelConfiguration()
//            let mlmodel = try MobileNet(configuration: config).model
//            return try VNCoreMLModel(for: mlmodel)
//        } catch {
//            print("❌ Failed to load model: \(error)")
//            return nil
//        }
//    }()
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//                // Display picked image or placeholder
//                Group {
//                    if let img = image {
//                        Image(uiImage: img)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(maxHeight: 300)
//                            .cornerRadius(12)
//                    } else {
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color.gray.opacity(0.2))
//                            .frame(height: 300)
//                            .overlay(Text("Tap below to select an image").foregroundColor(.secondary))
//                    }
//                }
//                
//                // Classification result
//                if isProcessing {
//                    ProgressView("Analyzing...")
//                } else {
//                    Text(classification)
//                        .font(.title3.bold())
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal)
//                }
//                
//                Spacer()
//                
//                // Buttons
//                Button("Select Image") {
//                    showingPicker = true
//                }
//                .buttonStyle(.borderedProminent)
//                .disabled(isProcessing)
//                
//                Button("Clear") {
//                    image = nil
//                    classification = ""
//                }
//                .buttonStyle(.bordered)
//                .disabled(isProcessing || image == nil)
//            }
//            .padding()
//            .navigationTitle("Image Classifier")
//            .sheet(isPresented: $showingPicker) {
//                ImagePicker(sourceType: .photoLibrary) { uiImage in
//                    showingPicker = false
//                    guard let uiImage else { return }
//                    classify(uiImage)
//                }
//            }
//        }
//    }
//    
//    private func classify(_ uiImage: UIImage) {
//        guard let vnModel else {
//            classification = "Model not loaded."
//            return
//        }
//        isProcessing = true
//        classification = ""
//        
//        // Prepare request
//        let request = VNCoreMLRequest(model: vnModel) { req, err in
//            defer { isProcessing = false }
//            if let err {
//                classification = "Vision error: \(err.localizedDescription)"
//                return
//            }
//            guard
//                let result = req.results?
//                    .compactMap({ $0 as? VNClassificationObservation })
//                    .first
//            else {
//                classification = "No results."
//                return
//            }
//            // Display top‐1 label with confidence
//            let name = result.identifier
//            let conf = String(format: "%.1f%%", result.confidence * 100)
//            classification = "\(name) (\(conf))"
//        }
//        request.imageCropAndScaleOption = .centerCrop
//        
//        // Convert to CGImage
//        guard let cgImage = uiImage.cgImage else {
//            classification = "Cannot get CGImage."
//            isProcessing = false
//            return
//        }
//        
//        // Perform on background queue
//        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: uiImage.cgImageOrientation, options: [:])
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try handler.perform([request])
//            } catch {
//                DispatchQueue.main.async {
//                    classification = "Handler error: \(error.localizedDescription)"
//                    isProcessing = false
//                }
//            }
//        }
//    }
//}
//
//// MARK: – UIImagePickerController bridge
//
//fileprivate struct ImagePicker: UIViewControllerRepresentable {
//    enum SourceType { case camera, photoLibrary }
//    var sourceType: SourceType
//    var onImagePicked: (UIImage?) -> Void
//    
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = sourceType == .camera
//            ? .camera
//            : .photoLibrary
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(onImage: onImagePicked)
//    }
//    
//    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let onImage: (UIImage?) -> Void
//        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }
//        func imagePickerController(
//            _ picker: UIImagePickerController,
//            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
//        ) {
//            let img = info[.originalImage] as? UIImage
//            onImage(img)
//        }
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            onImage(nil)
//        }
//    }
//}
//
//// MARK: – Helpers
//
//fileprivate extension UIImage {
//    // Map UIImageOrientation to CGImagePropertyOrientation
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
//// MARK: – Preview
//
//#Preview {
//    CoreMLImageClassifierView()
//}
