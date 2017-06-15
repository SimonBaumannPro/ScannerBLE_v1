//
//  scanButton.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 15/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit

class ScanButton: UIButton {
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.bluetoothBlueColor().cgColor
    }
    
    func buttonColorScheme(_ isScanning: Bool){
        let title = isScanning ? "Stop Scanning" : "Start Scanning"
        setTitle(title, for: UIControlState())
        
        let titleColor = isScanning ? UIColor.bluetoothBlueColor() : UIColor.white
        setTitleColor(titleColor, for: UIControlState())
        
        backgroundColor = isScanning ? UIColor.clear : UIColor.bluetoothBlueColor()
    }
}
