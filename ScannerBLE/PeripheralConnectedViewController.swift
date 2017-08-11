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
    @IBOutlet weak var deviceUUID: UILabel!
    @IBOutlet weak var propertyLabel: UILabel!
    
    var peripheral: CBPeripheral?
    var rssiReloadTimer: Timer?
    var services: [CBService] = []
    var characteristics : [[CBCharacteristic]]?
    var propertiesCharacterisctics : [String] = []
    var characteristicSelected: CBCharacteristic?
    var uuids: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        characteristics = [[CBCharacteristic]]()
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PeripheralConnectedViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        self.navigationItem.title = "Details"
        
        
        tableView.tableFooterView = UIView(frame: .zero) // Dismiss empty cell delimiters
        
        peripheral?.delegate = self
        peripheralName.text = peripheral?.name ?? "No Device Name"
        
        deviceUUID.text = peripheral?.identifier.uuidString
        
        let blurEffect = UIBlurEffect(style: .light)
        blurView.effect = blurEffect
        tableView.contentInset.top = 1
        
        // Reload the RSSI value of the connected perph each sec
        rssiReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PeripheralConnectedViewController.refreshRSSI), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Reload the RSSI value of the connected perph each sec
        rssiReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PeripheralConnectedViewController.refreshRSSI), userInfo: nil, repeats: true)
    }
    
    //Update the actual RSSI value of the connected peripheral
    func refreshRSSI() {
        peripheral?.readRSSI()
    }
    
    func back(sender : UIBarButtonItem) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disconnectPeripheral"), object: nil)
        _ = navigationController?.popViewController(animated: true)
    }
    
    // Create a String with the properties of a characteristic
    func propertiesToString(charac : CBCharacteristic) -> String {
        return charac.getProperties().flatMap({ "\($0)" }).joined(separator: ", ")
    }
    
    // Send BLE data to the ServiceCharacteristicController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let selectedCell = sender as? UITableViewCell else {return}
        
        guard let selectedIndexPath = tableView.indexPath(for: selectedCell) else {return}
        
        guard let serviceCharacteristicController = segue.destination as? ServiceCharacteristicViewController else {return}
        
        guard let characteristicSelected = characteristics?[selectedIndexPath.section][selectedIndexPath.row] else {return}
        
        serviceCharacteristicController.peripheral = peripheral
        serviceCharacteristicController.service = services[selectedIndexPath.section]
        serviceCharacteristicController.characteristic = characteristicSelected
        serviceCharacteristicController.properties = propertiesToString(charac: characteristicSelected)
    }
}

extension PeripheralConnectedViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return characteristics?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceCell", for: indexPath) as! ServiceTableViewCell
        let properties = propertiesToString(charac: (characteristics?[indexPath.section][indexPath.row])!)
        
        cell.characteristicUUID.text = characteristics?[indexPath.section][indexPath.row].uuid.description
        
        cell.propertyLabel.text = "Properties : ".appending(properties)
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
        return cell
    }
}

extension PeripheralConnectedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.00
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return services[section].uuid.description
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characteristics![section].count
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        headerView.contentView.backgroundColor = UIColor.white
        headerView.textLabel?.textColor = UIColor.black
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
}

extension PeripheralConnectedViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        if error != nil {
            print("Error discovering services: \(String(describing: error?.localizedDescription))")
        }
        
        peripheral.services?.forEach({ (service) in
            peripheral.discoverCharacteristics(nil, for: service)
            services.append(service)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor : \(service.uuid.uuidString)")
        if error != nil {
            print("Error discovering service characteristics: \(String(describing: error?.localizedDescription))")
        }
        
        print("Service UUID : \(service.uuid)")
        var charactsOfThisService = [CBCharacteristic]()
        
        service.characteristics?.forEach({ (characteristic) in
            print("\(String(describing: characteristic.uuid))---\(String(describing: characteristic.properties.rawValue))")
            
            charactsOfThisService.append(characteristic)
        })
        
        characteristics?.append(charactsOfThisService)
        tableView.reloadData()
    }
    
    // Display the RSSI value of a device
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
        rssiLabel.text = "RSSI : \(RSSI)dB"
    }
}

extension CBCharacteristic {
    
    // Obtain the properties string array according to the `self.properties`.
    func getProperties() -> [String] {
        let properties = self.properties.rawValue
        let broadcast = CBCharacteristicProperties.broadcast.rawValue
        let read = CBCharacteristicProperties.read.rawValue
        let writeWithoutResponse = CBCharacteristicProperties.writeWithoutResponse.rawValue
        let write = CBCharacteristicProperties.write.rawValue
        let notify = CBCharacteristicProperties.notify.rawValue
        let indicate = CBCharacteristicProperties.indicate.rawValue
        let authenticatedSignedWrites = CBCharacteristicProperties.authenticatedSignedWrites.rawValue
        let extendedProperties = CBCharacteristicProperties.extendedProperties.rawValue
        let notifyEncryptionRequired = CBCharacteristicProperties.notifyEncryptionRequired.rawValue
        let indicateEncryptionRequired = CBCharacteristicProperties.indicateEncryptionRequired.rawValue
        var resultProperties = [String]()
        if properties & broadcast > 0 {
            resultProperties.append("Broadcast")
        }
        if properties & read > 0 {
            resultProperties.append("Read")
        }
        if properties & write > 0 {
            resultProperties.append("Write")
        }
        if properties & writeWithoutResponse > 0 {
            resultProperties.append("Write Without Response")
        }
        
        if properties & notify > 0 {
            resultProperties.append("Notify")
        }
        if properties & indicate > 0 {
            resultProperties.append("Indicate")
        }
        if properties & authenticatedSignedWrites > 0 {
            resultProperties.append("Authenticated Signed Writes")
        }
        if properties & extendedProperties > 0 {
            resultProperties.append("Extended Properties")
        }
        if properties & notifyEncryptionRequired > 0 {
            resultProperties.append("Notify Encryption Required")
        }
        if properties & indicateEncryptionRequired > 0 {
            resultProperties.append("Indicate Encryption Required")
        }
        return resultProperties
    }
}
