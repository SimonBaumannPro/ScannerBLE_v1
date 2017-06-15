//
//  PeripheralConnectedViewController.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 14/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralConnectedViewController: UIViewController {


    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rssiLabel: UILabel!

    var peripheral: CBPeripheral?
    var rssiReloadTimer: Timer?
    var services: [CBService] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheral?.delegate = self
        peripheralName.text = peripheral?.name
        
        let blurEffect = UIBlurEffect(style: .dark)
        blurView.effect = blurEffect
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80.0
        tableView.contentInset.top = 5
        
        rssiReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PeripheralConnectedViewController.refreshRSSI), userInfo: nil, repeats: true)
    }
    
    
    /* Update the actual RSSI value of the connected peripheral */
    func refreshRSSI() {
        peripheral?.readRSSI()
    }

    /* Disconnect the peripheral connected and return to the main frame */
    @IBAction func disconnectButtonPressed(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.5, animations: {self.view.alpha = 0.0}, completion: {_ in self.dismiss(animated: false, completion: nil)
        })
    }
}

extension PeripheralConnectedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell") as! ServiceTableViewCell
        cell.serviceNameLabel.text = "\(services[indexPath.row].uuid)"
        return cell
    }
}


extension PeripheralConnectedViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print(print("Error discovering services: \(String(describing: error?.localizedDescription))"))
        }
        
        peripheral.services?.forEach({ (service) in
            services.append(service)
            tableView.reloadData()
            peripheral.discoverCharacteristics(nil, for: service)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("Error discovering service characteristics: \(String(describing: error?.localizedDescription))")
        }
        
        service.characteristics?.forEach({ (characteristic) in
            print("\(String(describing: characteristic.descriptors))---\(characteristic.properties)")
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
        switch RSSI.intValue {
        case -90 ... -60:
            rssiLabel.textColor = UIColor.bluetoothOrangeColor()
            break
        case -200 ... -90:
            rssiLabel.textColor = UIColor.bluetoothRedColor()
            break
        default:
            rssiLabel.textColor = UIColor.bluetoothGreenColor()
        }
        
        rssiLabel.text = "\(RSSI)dB"
    }
}
