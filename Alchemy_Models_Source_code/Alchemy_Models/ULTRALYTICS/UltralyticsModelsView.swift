//
//  UltralyticsModelsView.swift
//  Alchemy_Models
//
//  Created by Cong Le on 4/21/25.
//

import SwiftUI

// Placeholder struct for model data
struct ModelInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let link: String? // Placeholder for potential navigation
    let isNew: Bool = false
}

// Placeholder struct for FAQ data
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let pythonCode: String? = nil
    let cliCode: String? = nil
    let hasCodeExample: Bool = false
}

struct UltralyticsModelsView: View {
    
    // --- Data (Extracted from Markdown) ---

    let featuredModels: [ModelInfo] = [
        ModelInfo(name: "YOLOv3", description: "The third iteration of the YOLO model family, originally by Joseph Redmon, known for its efficient real-time object detection capabilities.", link: "yolov3.md"),
        ModelInfo(name: "YOLOv4", description: "A darknet-native update to YOLOv3, released by Alexey Bochkovskiy in 2020.", link: "yolov4.md"),
        ModelInfo(name: "YOLOv5", description: "An improved version of the YOLO architecture by Ultralytics, offering better performance and speed trade-offs compared to previous versions.", link: "yolov5.md"),
        ModelInfo(name: "YOLOv6", description: "Released by Meituan in 2022, and in use in many of the company's autonomous delivery robots.", link: "yolov6.md"),
        ModelInfo(name: "YOLOv7", description: "Updated YOLO models released in 2022 by the authors of YOLOv4.", link: "yolov7.md"),
        ModelInfo(name: "YOLOv8", description: "A versatile model featuring enhanced capabilities such as instance segmentation, pose/keypoints estimation, and classification.", link: "yolov8.md"),
        ModelInfo(name: "YOLOv9", description: "An experimental model trained on the Ultralytics YOLOv5 codebase implementing Programmable Gradient Information (PGI).", link: "yolov9.md"),
        ModelInfo(name: "YOLOv10", description: "By Tsinghua University, featuring NMS-free training and efficiency-accuracy driven architecture, delivering state-of-the-art performance and latency.", link: "yolov10.md"),
        ModelInfo(name: "YOLO11", description: "Ultralytics' latest YOLO models delivering state-of-the-art (SOTA) performance across multiple tasks including detection, segmentation, pose estimation, tracking, and classification.", link: "yolo11.md"),
        ModelInfo(name: "Segment Anything Model (SAM)", description: "Meta's original Segment Anything Model (SAM).", link: "sam.md"),
        ModelInfo(name: "Segment Anything Model 2 (SAM2)", description: "The next generation of Meta's Segment Anything Model (SAM) for videos and images.", link: "sam-2.md"),
        ModelInfo(name: "Mobile Segment Anything Model (MobileSAM)", description: "MobileSAM for mobile applications, by Kyung Hee University.", link: "mobile-sam.md"),
        ModelInfo(name: "Fast Segment Anything Model (FastSAM)", description: "FastSAM by Image & Video Analysis Group, Institute of Automation, Chinese Academy of Sciences.", link: "fast-sam.md"),
        ModelInfo(name: "YOLO-NAS", description: "YOLO Neural Architecture Search (NAS) Models.", link: "yolo-nas.md"),
        ModelInfo(name: "Realtime Detection Transformers (RT-DETR)", description: "Baidu's PaddlePaddle Realtime Detection Transformer (RT-DETR) models.", link: "rtdetr.md"),
        ModelInfo(name: "YOLO-World", description: "Real-time Open Vocabulary Object Detection models from Tencent AI Lab.", link: "yolo-world.md"),
        ModelInfo(name: "YOLOE", description: "An improved open-vocabulary object detector that maintains YOLO's real-time performance while detecting arbitrary classes beyond its training data.", link: "yoloe.md")
    ]
    
    let faqItems: [FAQItem] = [
        FAQItem(
            question: "What are the key advantages of using Ultralytics YOLO11 for object detection?",
            answer: "Ultralytics YOLO11 offers enhanced capabilities such as real-time object detection, instance segmentation, pose estimation, and classification. Its optimized architecture ensures high-speed performance without sacrificing accuracy, making it ideal for a variety of applications across diverse AI domains. YOLO11 builds on previous versions with improved performance and additional features, as detailed on the [YOLO11 documentation page](../models/yolo11.md)."), // Link handling needed
        FAQItem(
            question: "How can I train a YOLO model on custom data?",
            answer: "Training a YOLO model on custom data can be easily accomplished using Ultralytics' libraries. Here's a quick example:"),
//            pythonCode: """
//            from ultralytics import YOLO
//
//            # Load a YOLO model
//            model = YOLO("yolo11n.pt")  # or any other YOLO model
//
//            # Train the model on custom dataset
//            results = model.train(data="custom_data.yaml", epochs=100, imgsz=640)
//            """,
//            cliCode: """
//            yolo train model=yolo11n.pt data='custom_data.yaml' epochs=100 imgsz=640
//            """,
//            hasCodeExample: true),
        FAQItem(
            question: "Which YOLO versions are supported by Ultralytics?",
            answer: "Ultralytics supports a comprehensive range of YOLO (You Only Look Once) versions from YOLOv3 to YOLO11, along with models like YOLO-NAS, SAM, and RT-DETR. Each version is optimized for various tasks such as detection, segmentation, and classification. For detailed information on each model, refer to the [Models Supported by Ultralytics](../models/index.md) documentation."), // Link handling needed
        FAQItem(
            question: "Why should I use Ultralytics HUB for machine learning projects?",
            answer: "[Ultralytics HUB](../hub/index.md) provides a no-code, end-to-end platform for training, deploying, and managing YOLO models. It simplifies complex workflows, enabling users to focus on model performance and application. The HUB also offers [cloud training capabilities](../hub/cloud-training.md), comprehensive dataset management, and user-friendly interfaces for both beginners and experienced developers."), // Link handling needed
        FAQItem(
            question: "What types of tasks can YOLO11 perform, and how does it compare to other YOLO versions?",
            answer: "YOLO11 is a versatile model capable of performing tasks including object detection, instance segmentation, classification, and pose estimation. Compared to earlier versions, YOLO11 offers significant improvements in speed and accuracy due to its optimized architecture and anchor-free design. For a deeper comparison, refer to the [YOLO11 documentation](../models/yolo11.md) and the [Task pages](../tasks/index.md) for more details on specific tasks.") // Link handling needed
    ]

    // --- Body ---
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Title
                Text("Models Supported by Ultralytics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)

                // Introduction
                Text("Welcome to Ultralytics' model documentation! We offer support for a wide range of models, each tailored to specific tasks like object detection, instance segmentation, image classification, pose estimation, and multi-object tracking. If you're interested in contributing your model architecture to Ultralytics, check out our ")
                + Text("Contributing Guide").foregroundColor(.blue) // Placeholder Link
                + Text(".")
                
                // Hero Image
                AsyncImage(url: URL(string: "https://raw.githubusercontent.com/ultralytics/assets/refs/heads/main/yolo/performance-comparison.png")) { image in
                    image.resizable()
                         .scaledToFit()
                         .cornerRadius(8)
                } placeholder: {
                    ProgressView()
                        .frame(height: 200) // Placeholder height
                }
                .padding(.vertical)

                // Featured Models Section
                SectionHeader(title: "Featured Models")
                
                // Using VStack and ForEach for numbered list effect
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(Array(featuredModels.enumerated()), id: \.element.id) { index, model in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .fontWeight(.medium)
                                .frame(width: 25, alignment: .leading) // Align numbers

                             VStack(alignment: .leading) {
                                HStack {
                                    Text(model.name)
                                        .fontWeight(.bold)
                                        // Add Link behavior if needed here using actual URLs
                                        // .onTapGesture { /* Handle navigation for model.link */ }
                                        // .foregroundColor(.blue)

                                    if model.isNew {
                                        Text("🚀 NEW")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 5)
                                            .background(Color.red.opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(5)
                                    }
                                }

                                Text(model.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                             }
                             Spacer() // Push content to the left
                        }
                    }
                }
                
                // Embedded Video Placeholder
                GroupBox {
                    VStack {
                        // Placeholder for the video - could use WebView with WebKit
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                            )
                            .cornerRadius(8)

                        // Link to the actual video
                        Link(destination: URL(string: "https://www.youtube.com/embed/MWq1UxqTClU?si=nHAW-lYDzrz68jR0")!) {
                             Text("Watch: Run Ultralytics YOLO models in just a few lines of code.")
                                .font(.caption)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 5)
                    }
                }
                .padding(.vertical)

                // Getting Started Section
                SectionHeader(title: "Getting Started: Usage Examples")
                Text("This example provides simple YOLO training and inference examples. For full documentation on these and other modes see the Predict, Train, Val and Export docs pages.")
                    // Add links for Predict, Train, etc. here if needed
                    .padding(.bottom, 5)

                CodeExampleView(
                    pythonCode: """
                    from ultralytics import YOLO

                    # Load a COCO-pretrained YOLOv8n model
                    model = YOLO("yolov8n.pt")

                    # Display model information (optional)
                    model.info()

                    # Train the model on the COCO8 example dataset for 100 epochs
                    results = model.train(data="coco8.yaml", epochs=100, imgsz=640)

                    # Run inference with the YOLOv8n model on the 'bus.jpg' image
                    results = model("path/to/bus.jpg")
                    """,
                    cliCode: """
                    # Load a COCO-pretrained YOLOv8n model and train it on the COCO8 example dataset for 100 epochs
                    yolo train model=yolov8n.pt data=coco8.yaml epochs=100 imgsz=640

                    # Load a COCO-pretrained YOLOv8n model and run inference on the 'bus.jpg' image
                    yolo predict model=yolov8n.pt source=path/to/bus.jpg
                    """
                )

                // Contributing Section
                SectionHeader(title: "Contributing New Models")
                Text("Interested in contributing your model to Ultralytics? Great! We're always open to expanding our model portfolio.")
                    .padding(.bottom, 5)
                
                VStack(alignment: .leading, spacing: 8) {
                    ContributionStep(number: 1, text: "Fork the Repository: Start by forking the Ultralytics GitHub repository.") // Add link
                    ContributionStep(number: 2, text: "Clone Your Fork: Clone your fork to your local machine and create a new branch to work on.")
                    ContributionStep(number: 3, text: "Implement Your Model: Add your model following the coding standards and guidelines provided in our Contributing Guide.") // Add link
                    ContributionStep(number: 4, text: "Test Thoroughly: Make sure to test your model rigorously, both in isolation and as part of the pipeline.")
                    ContributionStep(number: 5, text: "Create a Pull Request: Once you're satisfied with your model, create a pull request to the main repository for review.")
                    ContributionStep(number: 6, text: "Code Review & Merging: After review, if your model meets our criteria, it will be merged into the main repository.")
                }
                .padding(.bottom, 5)
                
                // Add Link to Contributing Guide
                 Text("For detailed steps, consult our ")
                 + Text("Contributing Guide.").foregroundColor(.blue) // Placeholder Link

                // FAQ Section
                SectionHeader(title: "FAQ")
                ForEach(faqItems) { item in
                    DisclosureGroup(item.question) {
                        VStack(alignment: .leading) {
                            Text(.init(item.answer)) // Use .init for potential Markdown
                                .padding(.top, 5)
                                .padding(.bottom, item.hasCodeExample ? 10 : 0)
                                // Need logic here to parse and display links within the answer

                            if item.hasCodeExample {
                                CodeExampleView(pythonCode: item.pythonCode, cliCode: item.cliCode)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure VStack takes full width
                    }
                    Divider()
                }

            }
            .padding() // Add padding around the entire content
        }
    }
}

// --- Reusable Helper Views ---

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.bottom, 2)
    }
}

struct ContributionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .fontWeight(.medium)
                .frame(width: 20, alignment: .leading)
            Text(.init(text)) // Allow potential Markdown in step text
        }
    }
}

struct CodeExampleView: View {
    let pythonCode: String?
    let cliCode: String?
    
    @State private var selectedTab = 0 // 0 for Python, 1 for CLI

    var body: some View {
         VStack {
             Picker("Language", selection: $selectedTab) {
                 Text("Python").tag(0)
                 Text("CLI").tag(1)
             }
             .pickerStyle(.segmented)
             .padding(.bottom, 5)

              GroupBox {
                 ScrollView(.horizontal, showsIndicators : false) { // Allow horizontal scrolling for long lines
                    Text(selectedTab == 0 ? (pythonCode ?? "N/A") : (cliCode ?? "N/A"))
                        .font(.system(.caption, design: .monospaced))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading) // Expand text horizontally
                        .textSelection(.enabled) // Allow text selection
                 }
             }
             // Optional: Add background color or border to GroupBox if needed
             // .background(Color.gray.opacity(0.1))
             // .cornerRadius(8)
         }
         .padding(.vertical, 5)
    }
}

// --- Preview ---

struct UltralyticsModelsView_Previews: PreviewProvider {
    static var previews: some View {
        UltralyticsModelsView()
    }
}

// Note: For actual navigation using links like "[YOLOv3](yolov3.md)",
// you would need a navigation framework (like NavigationView/NavigationStack)
// and a way to resolve these relative paths or map them to specific views
// within your app. The placeholder links above demonstrate where this logic
// would be integrated. Inline markdown links within Text need specific handling
// perhaps by splitting the string or using attributed strings if more complexity is needed.
