//
//  ViewController.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 13/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth

// Caracteristics of a BLE device
struct DisplayPeripheral{
    var peripheral: CBPeripheral?
    var lastRSSI: NSNumber?
    var isConnectable: Bool?
}

/*
 * Class PeripheralViewController
 * Manage the connection between the application and the BLE
 * devices
 */
class PeripheralViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scannerButton: ScanButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bluetoothIcon: UIImageView!
    
    var centralManager: CBCentralManager!
    var peripherals: [DisplayPeripheral] = []   // Array of peripherals detected
    var viewReloadTimer: Timer?
    var selectedPeripheral: CBPeripheral?       // Peripheral selected by the user to connect
    let deviceTableView = DeviceTableViewCell()
    let kitLoRaUUID = CBUUID(string: "B14470AF-4FC0-E0B2-35CA-2961ECEC8222")
    
    var connectionOk: Bool?
    
    let alertController = UIAlertController(title: "Bluetooth Error", message: "Please Activate Bluetooth", preferredStyle: UIAlertControllerStyle.alert)
    
    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
        (result  :UIAlertAction) -> Void in
        print("Ok pressed")
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        alertController.addAction(okAction)
        // Initialize the CoreBluetooth centralManager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        print("[log] - centralManager Initialized")
    }
    
    /* Disconnect the current peripheral connected */
    func disconnect(notification : NSNotification) {
        print("[log] - disconnectPeripheral Called")
        centralManager.cancelPeripheralConnection(selectedPeripheral!)
        peripherals.removeAll()
    }
    
    /*
     * Called when the disconnect button is pressed.
     * Send a notification to disconnect the peripheral
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        connectionOk = false
        // From the PeripheralConnectedViewController, allow the disconnection of the current connected peripheral
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralViewController.disconnect(notification:)),name:NSNotification.Name(rawValue: "disconnectPeripheral"), object: nil)
        
        viewReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PeripheralViewController.refreshScanView), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        super.viewWillAppear(animated)
        viewReloadTimer?.invalidate()
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func updateViewForScanning() {
        statusLabel.text = "Scanning BLE Devices ..."
        bluetoothIcon.pulseAnimation()
        bluetoothIcon.isHidden = false
        scannerButton.buttonColorScheme(true)
    }
    
    func updateViewForStopScanning() {
        let plural = peripherals.count > 1 ? "s" : ""
        statusLabel.text = "\(peripherals.count) Device\(plural) found"
        bluetoothIcon.layer.removeAllAnimations()
        bluetoothIcon.isHidden = true
        scannerButton.buttonColorScheme(false)
    }
    
    @IBAction func scanningButtonPressed(_ sender: Any) {
        centralManager!.isScanning ? stopScanning() : startScanning()
    }
    
    /* Scan for BLE peripheral */
    func startScanning() {
        
        var tabUUID: [CBUUID] = []
        peripherals = []
        
        tabUUID.append(kitLoRaUUID)
        
        print("[log] - Scanning...")
        let triggerTime = (Int64(NSEC_PER_SEC)*10) // Nanosec per sec
        
        // Scan devices and add them to the tableView
        self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        updateViewForScanning()
        
        // Interrupt the scan and update the view after a time deadline
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime)/Double(NSEC_PER_SEC), execute: { () -> Void in
            if self.centralManager.isScanning {
                self.stopScanning()
            }
        })
    }
    
    /* Stop the BLE peripheral Scan */
    func stopScanning () {
        centralManager.stopScan()
        updateViewForStopScanning()
        print("[log] - Scan stopped")
    }
    
    /* Refresh the tableView with the updated devices detected */
    func refreshScanView() {
        if (peripherals.count > 1 && centralManager.isScanning) {
            tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? PeripheralConnectedViewController {
            destinationViewController.peripheral = selectedPeripheral
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            if ident == "PeripheralConnectedSegue" && connectionOk! {
                return true
            }
        }
        return false
    }
}


extension PeripheralViewController : CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            print("[log] - Central Manager state = PoweredOn")
            startScanning()
        } else { // need to activate bluetooth
            let topController = UIApplication.topViewController()
            if centralManager!.isScanning {
                stopScanning()
            }
            topController?.present(alertController, animated: true, completion: nil)
            print("[log] - Central Manager state = BLE ERROR")
        }
    }
    
    /* The centralManager has discovered a (new?) BLE peripheral */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let peripheralName = peripheral.name
        
        // If the peripheral has already been detected, we just update its RSSI value
        for (index, foundPeripheral) in peripherals.enumerated() {
            if foundPeripheral.peripheral?.identifier == peripheral.identifier{
                peripherals[index].lastRSSI = RSSI
                return
            }
        }
        
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, isConnectable: isConnectable)
        if peripheralName != nil {
            if (peripheralName?.contains("test"))! {
                if (isConnectable) {
                    peripherals.append(displayPeripheral)
                }
                self.tableView.reloadData()
            }
        }
    }
}


extension PeripheralViewController : CBPeripheralDelegate {
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("FailToConnect")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if UIApplication.shared.isIgnoringInteractionEvents {
            print("ISIGNORING ... from PVC 1")
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        print("[log] - Peripheral connected")
        connectionOk = true
        performSegue(withIdentifier: "PeripheralConnectedSegue", sender: self)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[log] - Peripharal disconnected")
        self.dismiss(animated: true, completion: startScanning)
    }
}


extension PeripheralViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        tableView.separatorColor = UIColor.gray
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DeviceTableViewCell
        
        if !peripherals.isEmpty {
            cell.displayPeripheral = peripherals[indexPath.row]
            cell.delegate = self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
}

extension PeripheralViewController: DeviceCellDelegate {
    
    func connectPressed(_ peripheral: CBPeripheral) {
        
        // Stop scan before connection
        if centralManager.isScanning {
            stopScanning()
        }
        
        let triggerTime = (Int64(NSEC_PER_SEC)*5) // Nanosec per sec
        
        print("[log] - periph state :\(peripheral)")
        
        if peripheral.state != .connected {
            selectedPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
        
        // Block all touch event during connection
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime)/Double(NSEC_PER_SEC), execute: { () -> Void in
            if peripheral.state == .connecting {
                // It takes the title and the alert message and prefferred style
                let alertController = UIAlertController(title: "ERROR", message: "Connection failed", preferredStyle: .alert)
                
                // Then we create a default action for the alert...
                // It is actually a button and we have given the button text style and handler
                // currently handler is nil as we are not specifying any handler
                let defaultAction = UIAlertAction(title: "Close", style: .default, handler: nil)
                
                //now we are adding the default action to our alertcontroller
                alertController.addAction(defaultAction)
                
                //and finally presenting our alert using this method
                self.present(alertController, animated: true, completion: nil)
                
                // Cancel the connection
                self.centralManager.cancelPeripheralConnection(peripheral)
                
            }
            if UIApplication.shared.isIgnoringInteractionEvents {
                print("ISIGNORING ... from PVC 2")
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        })
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

