//
//  CollectionViewCell.swift
//  VirtualTourist
//
//  Created by Greybear on 6/10/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell{
  
    @IBOutlet weak var cellSpinner: UIActivityIndicatorView!
    @IBOutlet weak var photo: UIImageView!

    //Stop download if the cell is reused
    var cancelTaskOnReuse: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
