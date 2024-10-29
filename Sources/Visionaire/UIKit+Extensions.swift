//
//  UIKit+Extensions.swift
//  Visionaire
//
//  Created by enes öztürk on 29/10/2024.
//

import UIKit
import Vision

extension UIView {
    
    /// Flips the view vertically based on the `isFlipped` parameter.
    /// - Parameter isFlipped: A Boolean value that determines if the view should be flipped vertically.
    func flipped(_ isFlipped: Bool) {
        // Apply a vertical flip transformation if isFlipped is true, otherwise reset to identity.
        transform = isFlipped ? CGAffineTransform(scaleX: 1, y: -1) : .identity
    }

    /// Updates the size of the view's frame.
    /// - Parameter size: The new size to set for the view's frame.
    func setFrame(size: CGSize) {
        // Directly set the frame's size to the provided CGSize.
        frame.size = size
    }

    /// Updates the origin of the view's frame.
    /// - Parameter point: The new origin point to set for the view's frame.
    func setOffset(point: CGPoint) {
        // Directly set the frame's origin to the provided CGPoint.
        frame.origin = point
    }
    
    /// Draws bounding boxes for detected objects on the view.
    /// - Parameters:
    ///   - observations: An array of `VNDetectedObjectObservation` objects to draw.
    ///   - isFlipped: A Boolean value that determines if the view should be flipped vertically after drawing.
    ///   - drawingClosure: A closure that returns a UIView to be used as an overlay for each observation.
    func drawObservations(_ observations: [VNDetectedObjectObservation], isFlipped: Bool = true, drawingClosure: @escaping () -> UIView) {
        for observation in observations {
            // Convert the normalized bounding box to the view's coordinate system.
            let denormalizedRect = VNImageRectForNormalizedRect(observation.boundingBox, Int(frame.size.width), Int(frame.size.height))
            // Create an overlay view using the provided closure.
            let overlayView = drawingClosure()
            // Set the overlay's size and position.
            overlayView.setFrame(size: denormalizedRect.size)
            overlayView.setOffset(point: denormalizedRect.origin)
            // Add the overlay to the view.
            addSubview(overlayView)
        }
        // Flip the view if required.
        flipped(isFlipped)
    }
    
    /// Draws face landmarks on the view.
    /// - Parameters:
    ///   - observations: An array of `VNFaceObservation` objects to draw.
    ///   - landmarks: Specifies which landmarks to draw.
    ///   - isFlipped: A Boolean value that determines if the view should be flipped vertically after drawing.
    ///   - styleClosure: A closure that returns a UIView styled for the face landmarks.
    func drawFaceLandmarks(_ observations: [VNFaceObservation], landmarks: FaceLandmarks = .all, isFlipped: Bool = true, styleClosure: @escaping (VNFaceObservationShape) -> UIView) {
        // Create a shape view for the face landmarks using the provided closure.
        let shapeView = styleClosure(VNFaceObservationShape(observations: observations, enabledLandmarks: landmarks))
        // Add the shape view to the view.
        addSubview(shapeView)
        // Flip the view if required.
        flipped(isFlipped)
    }
    
    /// Draws quadrilateral shapes for rectangle observations on the view.
    /// - Parameters:
    ///   - observations: An array of `VNRectangleObservation` objects to draw.
    ///   - isFlipped: A Boolean value that determines if the view should be flipped vertically after drawing.
    ///   - styleClosure: A closure that returns a UIView styled for the rectangle shapes.
    func drawQuad(_ observations: [VNRectangleObservation], isFlipped: Bool = true, styleClosure: @escaping (VNRectangleObservationShape) -> UIView) {
        // Create a shape view for the rectangle observations using the provided closure.
        let shapeView = styleClosure(VNRectangleObservationShape(observations: observations))
        // Add the shape view to the view.
        addSubview(shapeView)
        // Flip the view if required.
        flipped(isFlipped)
    }
    
    /// Visualizes a mask for person segmentation on the view.
    /// - Parameter observations: An array of `VNPixelBufferObservation` objects representing the segmentation mask.
    func visualizePersonSegmentationMask(_ observations: [VNPixelBufferObservation]) {
        // Implement the logic to visualize the segmentation mask using UIKit.
    }
    
    /// Visualizes human body poses on the view.
    /// - Parameters:
    ///   - observations: An array of `VNHumanBodyPoseObservation` objects to draw.
    ///   - isFlipped: A Boolean value that determines if the view should be flipped vertically after drawing.
    ///   - styleClosure: A closure that returns a UIView styled for the body pose shapes.
    @available(iOS 14.0, *)
    func visualizeHumanBodyPose(_ observations: [VNHumanBodyPoseObservation], isFlipped: Bool = true, styleClosure: @escaping (VNHumanBodyPoseObservationShape) -> UIView) {
        // Create a shape view for the human body poses using the provided closure.
        let shapeView = styleClosure(VNHumanBodyPoseObservationShape(observations: observations))
        // Add the shape view to the view.
        addSubview(shapeView)
        // Flip the view if required.
        flipped(isFlipped)
    }
    
    /// Visualizes contour shapes on the view.
    /// - Parameters:
    ///   - observations: An array of `VNContoursObservation` objects to draw.
    ///   - isFlipped: A Boolean value that determines if the view should be flipped vertically after drawing.
    ///   - styleClosure: A closure that returns a UIView styled for the contour shapes.
    @available(iOS 14.0, *)
    func visualizeContours(_ observations: [VNContoursObservation], isFlipped: Bool = true, styleClosure: @escaping (VNContoursObservationShape) -> UIView) {
        // Create a shape view for the contour observations using the provided closure.
        let shapeView = styleClosure(VNContoursObservationShape(observations: observations))
        // Add the shape view to the view.
        addSubview(shapeView)
        // Flip the view if required.
        flipped(isFlipped)
    }
} 
