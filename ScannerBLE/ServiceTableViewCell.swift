//
//  ServiceTableViewCell.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 14/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit

class ServiceTableViewCell: UITableViewCell {

    @IBOutlet weak var characteristicUUID: UILabel!
    @IBOutlet weak var propertyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
