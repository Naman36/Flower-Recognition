//
//  ViewController.swift
//  Flower?
//
//  Created by Naman Soni on 08/09/19.
//  Copyright © 2019 Naman Soni. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    @IBOutlet weak var camera: UIBarButtonItem!
    @IBOutlet weak var imageP: UIImageView!
    let imagePicker  = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            
            guard let ciimage = CIImage(image: image) else{
                fatalError("Failed to convert to CIImage")
            }
            detect(flowerImage: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    func detect(flowerImage:CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Cannot import model")
            }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else{
                fatalError("results not obtained")
            }
            self.navigationItem.title = classification.identifier.capitalized
            self.getinfo(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        
    }
    func getinfo(flowerName : String){
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids": "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]

        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                let flowerJSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageP.sd_setImage(with: URL(string: flowerURL))
                self.label.text = flowerDescription
                
            }
        }
    }
}

