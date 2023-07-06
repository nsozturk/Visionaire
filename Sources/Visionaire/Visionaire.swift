import Vision
import CoreImage

let kVisionaireContext: CIContext = CIContext(options: [.name: "VisionaireCIContext"])

public final class Visionaire: ObservableObject {

    public static let shared = Visionaire()

    public init() {

    }

    @Published public var isProcessing: Bool = false

    public func warmup(tasks: [VisionTask]) {
        let smallRect  = CGRect(x: 0, y: 0, width: 64, height: 64)
        let solidImage = CIImage(color: .red).cropped(to: smallRect)
        Task {
            do {
                let _ = try await performTasks(tasks, onImage: solidImage)
                debugPrint("[Visionaire] Warmed up...")
            } catch {
                debugPrint(error)
            }
        }
    }
}

//MARK: - Image Handlers
extension Visionaire {

    private func imageHandler(for image: CIImage, context: CIContext? = nil) -> VNImageRequestHandler {
        VNImageRequestHandler(ciImage: image, options: [.ciContext: context ?? kVisionaireContext])
    }

}

//MARK: - Task Execution
extension Visionaire {

    //MARK: Multiple tasks

    public func performTasks(_ tasks: [VisionTask],
                             ciContext context: CIContext? = nil,
                             onImage image: CIImage,
                             regionOfInterest: CGRect? = nil,
                             revision: Int? = nil,
                             preferBackgroundProcessing: Bool = false
    ) async throws -> [VisionTaskResult] {

        await MainActor.run {
            isProcessing = true
        }

        var taskResults = [VisionTaskResult]()

        let requests = tasks.map {
            let request = $0.request(revision: revision) { request, error in
                taskResults.append(VisionTaskResult(request: request, error: error))
            }

            if let regionOfInterest {
                request.regionOfInterest = regionOfInterest
            }

            if preferBackgroundProcessing {
                request.preferBackgroundProcessing = true
            }

            return request
        }

        do {
            try imageHandler(for: image, context: context).perform(requests)
            await MainActor.run {
                isProcessing = false
            }
        } catch {
            await MainActor.run {
                isProcessing = false
            }
            throw error
        }

        return taskResults
    }

    //MARK: Single Task

    public func performTask(_ task: VisionTask,
                            ciContext context: CIContext? = nil,
                            onImage image: CIImage,
                            regionOfInterest: CGRect? = nil,
                            revision: Int? = nil,
                            preferBackgroundProcessing: Bool = false
    ) async throws -> VisionTaskResult {
        try await performTasks([task],
                               ciContext: context,
                               onImage: image,
                               regionOfInterest: regionOfInterest,
                               revision: revision,
                               preferBackgroundProcessing: preferBackgroundProcessing).first!
    }

}

//MARK: - Observation Casting

extension Visionaire {

    private func multiObservationHandler<T>(_ task: VisionTask, image: CIImage) async throws -> [T] {
        let result = try await performTask(task, onImage: image)

        if let error = result.error {
            throw error
        }

        return result.observations.compactMap { $0 as? T }
    }

    private func singleObservationHandler<T>(_ task: VisionTask, image: CIImage) async throws -> T {
        let result = try await performTask(task, onImage: image)
        guard let observation = result.observations.first, let first = observation as? T else {
            throw VisionaireError.noObservations
        }
        return first
    }

}

//MARK: - Convenience Methods (Observation Based)

extension Visionaire {

    public func horizonDetection(image: CIImage) async throws -> VNHorizonObservation {
        try await singleObservationHandler(.horizonDetection, image: image)
    }

    public func saliencyAnalysis(mode: SaliencyMode, image: CIImage) async throws -> [VNSaliencyImageObservation] {
        try await multiObservationHandler(mode.task, image: image)
    }

    public func saliencyAnalysis(mode: SaliencyMode, image: CIImage) async throws -> [VNRectangleObservation] {
        let saliency: [VNSaliencyImageObservation] = try await multiObservationHandler(mode.task, image: image)
        return saliency.flatMap { $0.salientObjects ?? [] }
    }

    public func faceDetection(image: CIImage, regionOfInterest: CGRect? = nil, revision: Int? = nil) async throws -> [VNFaceObservation] {
        try await multiObservationHandler(.faceDetection, image: image)
    }

    public func faceLandmarkDetection(image: CIImage, regionOfInterest: CGRect? = nil, revision: Int? = nil) async throws -> [VNFaceObservation] {
        try await multiObservationHandler(.faceLandmarkDetection, image: image)
    }

    public func faceCaptureQualityDetection(image: CIImage, regionOfInterest: CGRect? = nil, revision: Int? = nil) async throws -> [VNFaceObservation] {
        try await multiObservationHandler(.faceCaptureQuality, image: image)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 13.0, *)
    public func personSegmentation(image: CIImage, qualityLevel: VNGeneratePersonSegmentationRequest.QualityLevel) async throws -> [VNPixelBufferObservation] {
        try await multiObservationHandler(.personSegmentation, image: image)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 13.0, *)
    public func documentSegmentation(image: CIImage) async throws -> [VNRectangleObservation] {
        try await multiObservationHandler(.documentSegmentation, image: image)
    }

}
