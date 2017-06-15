//
//  DeviceTableViewCell.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 13/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth


protocol DeviceCellDelegate: class {
    func connectPressed(_ peripheral: CBPeripheral)
}


class DeviceTableViewCell: UITableViewCell {
    

    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceRssiLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    var delegate: DeviceCellDelegate?
    
    var displayPeripheral: DisplayPeripheral? {
        didSet {
            print("displayPeripheral")
            if let deviceName = displayPeripheral!.peripheral?.name {
                deviceNameLabel.text = deviceName.isEmpty ? "No device name" : deviceName
            } else {
                deviceNameLabel.text = "No device Name"
            }
            
            if let rssi = displayPeripheral!.lastRSSI {
                deviceRssiLabel.text = "\(rssi)dB"
            }
            
            connectButton.isHidden = !(displayPeripheral?.isConnectable!)!
        }
    }
    
    
    @IBAction func connectButtonPressed(_ sender: Any) {
        delegate?.connectPressed((displayPeripheral?.peripheral)!)
    }
}

