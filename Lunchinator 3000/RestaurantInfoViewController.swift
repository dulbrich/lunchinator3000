//
//  RestaurantInfoView.swift
//  Lunchinator 3000
//
//  Created by David Ulbrich on 7/12/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import UIKit

//TODO: Use a better data storage system.
var currentRestaurantName = ""
var currentRestaurantWaitTime = NSNumber(integerLiteral: 0)
var currentRestaurantImage = "Arbys.jpeg"

class RestaurantInfoView: UIViewController {
    
    @IBOutlet weak var restaurantName: UILabel!
    @IBOutlet weak var restaurantStars: UIImageView!
    @IBOutlet weak var restaurantImage: UIImageView!
    @IBOutlet weak var restaurantWaitTime: UILabel!
    @IBOutlet weak var restaurantDescriptionText: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restaurantName.text = currentRestaurantName
        self.restaurantWaitTime.text = "\(currentRestaurantWaitTime) Minutes"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getRestaurantImage()
    }
    
    // URLSession used to get image.
    //TODO: Cache the images retrieved so they are not downloaded each time.
    func getRestaurantImage() {
        let restaurantURL = URL(string: imageEndpoint + currentRestaurantImage)
        let session = URLSession(configuration: .default)
        let downloadPicture = session.dataTask(with: restaurantURL!) { (data, response, error) in
            if let err = error {
                print("Error downloading cat picture: \(err)")
            } else {
                if let resp = response as? HTTPURLResponse {
                    print("Downloaded restaurant image with response code \(resp.statusCode)")
                    if let imageData = data {
                        let image = UIImage(data: imageData)
                        self.restaurantImage.image = image
                    } else {
                        print("Couldn't get image: Image is nil")
                    }
                } else {
                    print("Couldn't get response code for some reason")
                }
            }
        }
        downloadPicture.resume()
    }
}
