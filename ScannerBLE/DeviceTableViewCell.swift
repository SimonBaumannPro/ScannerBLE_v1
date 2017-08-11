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

/*
 * Manage the behaviors of elements contained in the DevicetableViewCell
 * Manage the interaction events on the DeviceTableView
 */
class DeviceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceRssiLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    var isConnecting: Bool = false
    var activityIndicator = UIActivityIndicatorView()
    let ActivityDelay = (Int64(NSEC_PER_SEC)*5)
    var delegate: DeviceCellDelegate?
    var displayPeripheral: DisplayPeripheral? {
        didSet {
            if let deviceName = displayPeripheral?.peripheral?.name {
                deviceNameLabel.text = deviceName.isEmpty ? "No device Name" : deviceName
            } else {
                deviceNameLabel.text = "No device Name"
            }
            
            if let rssi = displayPeripheral!.lastRSSI {
                deviceRssiLabel.text = "RSSI: \(rssi)dB"
            }
            
            // Connection button available only if isConnectable
            connectButton.isHidden = !(displayPeripheral?.isConnectable ?? false)
        }
    }
    
    @IBAction func connectButtonPressed(_ sender: Any) {
        if !(isConnecting) {
            isConnecting = true
            delegate?.connectPressed((displayPeripheral?.peripheral)!)
            connectButton.isHidden = true
            connectButton.isEnabled = false
            startActivityIndicator(uiView: self)
        }
    }
    
    // run the indicator connection inside the "connect" button frame clicked by the user
    func startActivityIndicator(uiView: UIView) {
        activityIndicator.frame = connectButton.frame
        activityIndicator.center = connectButton.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        uiView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(ActivityDelay)/Double(NSEC_PER_SEC)) {
            self.stopActivityIndicator()
            self.isConnecting = false
        }
    }
    
    func stopActivityIndicator() {
        activityIndicator.stopAnimating()
        connectButton.isHidden = false
        connectButton.isEnabled = true
    }
}
