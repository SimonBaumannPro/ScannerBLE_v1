//
//  ServiceTableViewCell.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 14/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit

class ServiceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var serviceNameLabel: UILabel!
    @IBOutlet weak var serviceCharasteristicsButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func charasteristicsButtonPressed(_ sender: AnyObject) {
    }

}
