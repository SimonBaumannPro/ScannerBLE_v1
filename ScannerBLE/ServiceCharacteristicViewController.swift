//
//  ServiceCharacteristicViewController.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 07/07/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth


class ServiceCharacteristicViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var writeDataTF: UITextField!
    @IBOutlet weak var dataRead: UITextField!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var characteristicLabel: UILabel!
    @IBOutlet weak var propertiesLabel: UILabel!
    @IBOutlet weak var switchLed: UISwitch!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    var service: CBService!
    var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    var properties: String?
    
    var readProperty : Bool = false
    var writeProperty : Bool = false
    
    var dataRedColor: Data?
    var dataWhiteColor: Data?
    let ledPayloadLength = 6
    // value send to the peripheral to put the blueled on
    let blueLedOn: [UInt8] = [0xFF]
    // value send to the peripheral to put the blueled off
    let blueLedOff: [UInt8] = [0x00]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataRead.delegate = self
        writeDataTF.delegate = self
        peripheral?.delegate = self
        
        getButton.layer.cornerRadius = 7
        sendButton.layer.cornerRadius = 7
        
        self.navigationItem.title = "Characteristics"
        
        readProperty = (characteristic?.properties.contains(CBCharacteristicProperties.read))!
        
        writeProperty = (characteristic?.properties.contains(CBCharacteristicProperties.write))!
        
        if (!writeProperty) {
            sendButton.backgroundColor = UIColor.red
            sendButton.isEnabled = false
            writeDataTF.isEnabled = false
            switchLed.isEnabled = false
        }
        
        if (!readProperty) {
            getButton.backgroundColor = UIColor.red
            getButton.isEnabled = false
        }
        
        characteristicLabel.text = "Characteristic : ".appending((characteristic?.uuid.description)!)
        propertiesLabel.text = "Properties : [".appending(properties!).appending("]")
        serviceLabel.text = service?.uuid.description
        
        if characteristicDiscovered() {
            
        }
    }
    
    @IBAction func switchLedPower(_ sender: UISwitch) {
        if switchLed.isOn {
            print("Blue led is now turned ON")
            let data = Data(bytes: blueLedOn)
            peripheral?.writeValue(data, for: characteristic!, type: CBCharacteristicWriteType.withResponse)
        } else {
            print("Led is now turned OFF")
            let data = Data(bytes: blueLedOff)
            peripheral?.writeValue(data, for: characteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // read the data from a characteristic
    @IBAction func getValue(_ sender: Any) {
        peripheral?.readValue(for: characteristic!)
    }
    
    // write data to a characteristic
    @IBAction func writeValue(_ sender: Any) {
    }
    
    // Dismiss the keyboard when click on "return"
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func characteristicDiscovered() -> Bool{
        return service.characteristics != nil
    }
}

extension ServiceCharacteristicViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed… error:  \(error)")
            return
        }
        
        // The value get from the device
        guard let temp = characteristic.value?[0] else {return}
        let RealTemp = String(format: "%X", temp)
        
        dataRead.text? = ("Température : \(RealTemp)°C")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Value written ! :D")
    }
}
