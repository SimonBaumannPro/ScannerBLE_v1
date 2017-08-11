//
//  scanButton.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 15/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit

class ScanButton: UIButton {
    
    let clearBlue = UIColor(red:0.20, green:0.41, blue:0.87, alpha:1.0)
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.bluetoothBlueColor().cgColor
    }
    
    func buttonColorScheme(_ isScanning: Bool){
        let title = isScanning ? "Stop Scanning" : "Start Scanning"
        setTitle(title, for: UIControlState())
        
        let titleColor = isScanning ? clearBlue : UIColor.white
        setTitleColor(titleColor, for: UIControlState())
        
        backgroundColor = isScanning ? UIColor.white : UIColor.bluetoothBlueColor()
    }
}
