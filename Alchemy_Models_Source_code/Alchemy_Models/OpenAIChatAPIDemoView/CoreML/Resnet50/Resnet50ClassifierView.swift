//
//  Resnet50ClassifierView.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/20/25.
//

//  Requires: Xcode 15+, iOS 17+
//

import SwiftUI
import PhotosUI
import Vision
import CoreML

struct Resnet50ClassifierView: View {
    // MARK: – State
    @State private var selectedItem: PhotosPickerItem?   // PhotoPicker binding
    @State private var image: UIImage?                  // The selected image
    @State private var classification: String = ""      // Top‐1 label + confidence
    @State private var isProcessing = false             // Busy indicator
    
    // MARK: – Load VNCoreMLModel for Resnet50
    private let vnModel: VNCoreMLModel? = {
        do {
            let config = MLModelConfiguration()
            let mlmodel = try Resnet50(configuration: config).model
            return try VNCoreMLModel(for: mlmodel)
        } catch {
            print("❌ Failed to load Resnet50 model: \(error)")
            return nil
        }
    }()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // — Display selected image or placeholder
                Group {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .overlay(
                                Text("Tap “Select Image”")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                
                // — Show classification or a ProgressView
                if isProcessing {
                    ProgressView("Analyzing…")
                } else {
                    Text(classification)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // — PhotosPicker button
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Select Image", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isProcessing)
                .onChange(of: selectedItem) {
                    guard let item = selectedItem else { return }
                    classification = ""
                    isProcessing = true
                    // Load image data asynchronously
                    Task {
                        defer { isProcessing = false }
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data)
                        {
                            // Assign image before classification
                            image = uiImage
                            classify(uiImage)
                        }
                    }
                }
                
                // — Clear button
                Button("Clear") {
                    image = nil
                    classification = ""
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing || image == nil)
            }
            .padding()
            .navigationTitle("Resnet50 Classifier")
        }
    }
    
    // MARK: – Vision request to classify the UIImage
    private func classify(_ uiImage: UIImage) {
        guard let vnModel else {
            classification = "Model not loaded."
            return
        }
        
        isProcessing = true
        classification = ""
        
        let request = VNCoreMLRequest(model: vnModel) { req, err in
            DispatchQueue.main.async {
                self.isProcessing = false
                if let err {
                    self.classification = "Error: \(err.localizedDescription)"
                    return
                }
                guard
                    let top = req.results?
                        .compactMap({ $0 as? VNClassificationObservation })
                        .first
                else {
                    self.classification = "No results."
                    return
                }
                let name = top.identifier
                let conf = String(format: "%.1f%%", top.confidence * 100)
                self.classification = "\(name) (\(conf))"
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        
        guard let cgImage = uiImage.cgImage else {
            classification = "Cannot convert to CGImage."
            isProcessing = false
            return
        }
        
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: uiImage.cgImageOrientation,
            options: [:]
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.classification = "Handler error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}

// MARK: – UIImage → CGImageOrientation helper

fileprivate extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
            case .up:            return .up
            case .down:          return .down
            case .left:          return .left
            case .right:         return .right
            case .upMirrored:    return .upMirrored
            case .downMirrored:  return .downMirrored
            case .leftMirrored:  return .leftMirrored
            case .rightMirrored: return .rightMirrored
            @unknown default:    return .up
        }
    }
}

// MARK: – Preview

#Preview {
    Resnet50ClassifierView()
}
