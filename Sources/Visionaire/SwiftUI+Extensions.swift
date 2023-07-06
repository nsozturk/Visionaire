//
//  File.swift
//  
//
//  Created by Vasilis Akoinoglou on 5/7/23.
//

import SwiftUI
import Vision

public extension View {

    func drawObservations(_ observations: [VNDetectedObjectObservation], isFlipped: Bool = true, _ drawingClosure: @escaping () -> some View) -> some View {
        overlay(
            GeometryReader { reader in
                ForEach(observations, id: \.self) { observation in
                    let denormalizedRect = VNImageRectForNormalizedRect(observation.boundingBox, Int(reader.size.width), Int(reader.size.height))
                    drawingClosure()
                        .frame(width: denormalizedRect.size.width,
                               height: denormalizedRect.size.height)
                        .offset(x: denormalizedRect.origin.x,
                                y: denormalizedRect.origin.y)
                }
            }
            .scaleEffect(x: 1, y: isFlipped ? -1 : 1)
        )
    }

    func drawFaceLandmarks(_ observations: [VNFaceObservation], landmarks: FaceLandmarks = .all, _ styleClosure: @escaping (ScaledShape<FaceLandmarksShape>) -> some View) -> some View  {
        overlay(
            styleClosure(FaceLandmarksShape(observations: observations, enabledLandmarks: landmarks).scale(x: 1, y: -1))
        )
    }
}

public extension [VNDetectedObjectObservation] {
    func visionRects(isFlipped: Bool = true) -> some Shape {
        DetectorRectangles(observations: self)
            .scale(x: 1, y: isFlipped ? -1 : 1)
    }
}

struct DetectorRectangles: Shape {
    let observations: [VNDetectedObjectObservation]

    func path(in rect: CGRect) -> Path {
        Path { path in
            for normalizedRect in observations.map({ $0.boundingBox }) {
                path.addRect(VNImageRectForNormalizedRect(normalizedRect, Int(rect.size.width), Int(rect.size.height)))
            }
        }
    }
}

public struct FaceLandmarksShape: Shape {
    let observations: [VNFaceObservation]
    var enabledLandmarks: FaceLandmarks

    public func path(in rect: CGRect) -> Path {
        Path { path in
            for observation in observations {
                guard let landmarks = observation.landmarks else { return }
                let regions = landmarks.regionsFor(landmarks: enabledLandmarks)
                for region in regions {
                    let points = region.pointsInImage(imageSize: rect.size)
                    if #available(iOS 16.0, macOS 13.0, tvOS 16, *) {
                        switch region.pointsClassification {
                        case .disconnected:
                            for point in points {
                                let dotSize = 4.0
                                let dotRect = CGRect(origin: point, size: .init(width: dotSize, height: dotSize)).offsetBy(dx: -dotSize / 2, dy: -dotSize / 2)
                                path.addEllipse(in: dotRect)
                            }
                        case .openPath:
                            path.addLines(points)
                        case .closedPath:
                            path.addLines(points)
                            path.closeSubpath()
                        }
                    } else {
                        path.addLines(points)
                        path.closeSubpath()
                    }
                }
            }
        }
    }
}
