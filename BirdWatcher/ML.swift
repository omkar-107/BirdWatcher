//
//  ML.swift
//  BirdWatcher
//
//  Created by mini project on 25/04/24.
//

import Foundation
import CoreML
import Vision
import UIKit




func createImageClassifier() -> VNCoreMLModel {
    // Use a default model configuration.
    let defaultConfig = MLModelConfiguration()


    // Create an instance of the image classifier's wrapper class.
    let imageClassifierWrapper = try? MyImageClassifier_1(configuration: defaultConfig)


    guard let imageClassifier = imageClassifierWrapper else {
        fatalError("App failed to create an image classifier model instance.")
    }


    // Get the underlying model instance.
    let imageClassifierModel = imageClassifier.model


    // Create a Vision instance using the image classifier's model instance.
    guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
        fatalError("App failed to create a `VNCoreMLModel` instance.")
    }


    return imageClassifierVisionModel
}



struct ClassificationData {
    let identifier: String
    let confidence: Double
}

typealias ClassificationCompletionHandler = (([ClassificationData]) -> Void)



class VisionMLWorker {
    let coreModel: VNCoreMLModel
    private(set) var classificationRequest: VNCoreMLRequest?
    var completionHandler: ClassificationCompletionHandler? = nil

    // MARK: - Initializer

    init() throws {
        let config = MLModelConfiguration()
        do {
            let model       = try Birds(configuration: config).model
            let coreModel   = try VNCoreMLModel(for: model)
            self.coreModel  = coreModel
        }
        catch {
            print("Failed to load Vision ML model: \(error)")
            throw error
        }
    }
    
    func setupClassificationRequest() {
        let coreModel = self.coreModel
        let request = VNCoreMLRequest(model: coreModel) { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        }
        request.imageCropAndScaleOption = .centerCrop
#if targetEnvironment(simulator)
    request.usesCPUOnly = true
    #endif
        self.classificationRequest = request
    }
    
    
    func getClassifications(for image: UIImage,
                            completionHandler: @escaping ClassificationCompletionHandler) throws {

        guard let classificationRequest = self.classificationRequest else {
            print("Failed to perform classification.afgafhrehfxb ")
            throw VisionMLClassificationError.classificationFailed
        }

        // remember completion handler for later
        self.completionHandler = completionHandler

        // feed the orientation information since CGImage can't read UIImage orientation
        let imageOrientation = image.imageOrientation.rawValue
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(imageOrientation)),
              let ciImage = CIImage(image: image) else {
            print("Unable to create \(CIImage.self) from \(image).")
            throw VisionMLClassificationError.invalidImageFile
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage,
                                                orientation: orientation)
            do {
                try handler.perform([classificationRequest])
            }
            catch {
                // check VNCoreMLRequest's completion block for detailed error
                print("Failed to perform classification. \n\(error)")
            }
        }
    }
    
    func classify(){
        
        let image = UIImage(named: "abcd")
        // prepare core ML request
        guard let visionWorker = try? VisionMLWorker() else {
            return 
        }
        visionWorker.setupClassificationRequest()
        // process image async
        do {
            try self.getClassifications(for: image!) { (results) in
                DispatchQueue.main.async { [weak self] in
                    // update the UILabel or something..
                    print(results)
                    print("after classifiaction")
                    
                }
            }
        }
        catch {
            // handle errors appropriately.
        }
    }
    private func processClassifications(for request: VNRequest, error: Error?) {
        // todo: handle request.results or any error
    }

}



enum VisionMLClassificationError: Error {
    case invalidModelFile
    case invalidImageFile
    case classificationFailed
}



