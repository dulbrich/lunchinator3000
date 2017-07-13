//
//  ReviewView.swift
//  Lunchinator 3000
//
//  Created by David Ulbrich on 7/12/17.
//  Copyright © 2017 David Ulbrich. All rights reserved.
//

import UIKit

class ReviewView: UIViewController {
    
    @IBOutlet weak var reviewerName: UILabel!
    @IBOutlet weak var reviewerImage: UIImageView!
    @IBOutlet weak var reviewStars: UIImageView!
    @IBOutlet weak var reviewText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
