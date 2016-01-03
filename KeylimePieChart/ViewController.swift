//
//  ViewController.swift
//  KeylimePieChart
//
//  Created by Arjun Gupta on 9/26/15.
//  Copyright © 2015 ArjunGupta. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let pie = KeylimePie.init(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
        pie.useVariableSizeSlicing          = true  // Slices popping out design. AKA Cox comb
        pie.adjustGraphRadiusToFillLabels   = true  // Off by default. True will reduce graph radius for fitting labels
        self.view.addSubview(pie)
        pie.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        
        pie.keysAndValues = [
            "Banana" : 15,
            "Fig" : 15,
            "Jackfruit" : 45,
            "Peach" : 7,
            "Grape" : 25,
            "Squash": 30,
            "Papaya" : 12,
            "Mango" : 10,
        ]
        
        //You can put in your own colors as well
        //check -> pieColorArray
        
        pie.build()
    }
    
    
}

