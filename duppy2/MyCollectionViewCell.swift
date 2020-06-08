//
//  MyCollectionViewCell.swift
//  CollectionApp
//
//  Created by ipodtouchdude on 07/06/2020.
//  Copyright © 2020 ipodtouchdude. All rights reserved.
//

import UIKit

class MyCollectionViewCell: UICollectionViewCell {

    @IBOutlet var appIcon: UIImageView!
    @IBOutlet var appName: UILabel!
    @IBOutlet var appStatus: UILabel!
    
    public func configure(image: UIImage, name: String) {
        appIcon.image = image
        appName.text = name
    }
}
