//
//  RestaurantDetails.swift
//  Lunchinator 3000
//
//  Created by David Ulbrich on 7/11/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import UIKit

class RestaurantDetails: UIViewController {
    
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var reviewsView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = currentRestaurantName
        self.reviewsView.alpha = 0
        
        //Change the appearence of the segmented control
        self.segmentedControl.layer.cornerRadius = 0.0
        self.segmentedControl.layer.borderWidth = 1.0
        self.segmentedControl.layer.borderColor = UIColor(colorLiteralRed: 27/255.0, green: 122/255.0, blue: 185/255.0, alpha: 185/255.0).cgColor
        self.segmentedControl.layer.masksToBounds = true
    }
    
    //This should toggle between details and reviews
    @IBAction func showDetailsOrReviews(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.detailsView.alpha = 1
                self.reviewsView.alpha = 0
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.detailsView.alpha = 0
                self.reviewsView.alpha = 1
            })
        }
    }
    
    
}
