//
//  ViewController.swift
//  CoreMLIntroduction
//
//  Created by AppWebStudios on 14/12/17.
//  Copyright © 2017 AppWebStudios. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate {

    
    
    @IBOutlet weak var imgPhoto: UIImageView!
    
    @IBOutlet weak var lblTextMsg: UILabel!
    
    var model: Inceptionv3!
    
    @IBOutlet weak var backViewImage: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        backViewImage.alpha = 0.0
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        model = Inceptionv3()
        
    }

   //MARK: - Action for opening camera
    @IBAction func btnCamera(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPickerController = UIImagePickerController()
        cameraPickerController.delegate = self
        cameraPickerController.sourceType = .camera
        cameraPickerController.allowsEditing = false
        
        present(cameraPickerController, animated: true, completion: nil)
        
    }
    
    //MARK: - Action for opening library
    @IBAction func btnLibrary(_ sender: Any) {
        
        let photoLibController = UIImagePickerController()
        photoLibController.delegate = self
        photoLibController.sourceType = .photoLibrary
        photoLibController.allowsEditing = false
        
        present(photoLibController, animated: true, completion: nil)
        
    }
    
    
    //MARK: - Shadows for Image back view
    func shadowForBackView(){
        
        backViewImage.alpha = 1.0
        
        backViewImage.layer.shadowOpacity = 0.5
        backViewImage.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        backViewImage.layer.shadowColor = UIColor.blue.cgColor
        backViewImage.layer.shadowRadius = 20.0
        
    }
    
    
    
}


extension ViewController: UIImagePickerControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        lblTextMsg.text = "Analyzing Image..."
        
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299.0, height: 299.0), true, 2.0)
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: 299.0, height: 299.0))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        imgPhoto.image = newImage

        
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        lblTextMsg.text = String(format: "I think this is %@", prediction.classLabel)
        
        /*Add shadow*/
        self.shadowForBackView()
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
}


