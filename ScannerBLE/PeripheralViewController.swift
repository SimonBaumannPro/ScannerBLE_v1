//
//  ViewController.swift
//  ScannerBLE
//
//  Created by Simon BAUMANN on 13/06/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth


/* Caracteristics of a BLE device */
struct DisplayPeripheral{
    var peripheral: CBPeripheral?
    var lastRSSI: NSNumber?
    var isConnectable: Bool?
}

/*
 * Class PeripheralViewController
 * Manage the connection between the application and the BLE devices
 * More detail here ...
 */
class PeripheralViewController: UIViewController {

    /* IBOutlets declarations */
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scannerButton: ScanButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bluetoothIcon: UIImageView!
    
    
    /* var declarations */
    var centralManager: CBCentralManager!
    var peripherals: [DisplayPeripheral] = []   // Array of peripherals detected
    var viewReloadTimer: Timer?
    var selectedPeripheral: CBPeripheral?       // Peripheral selected by the user to connect
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Initialize the CoreBluetooth centralManager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        print("[log] - centralManager Initialized")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[log] - viewWillAppear called")
        viewReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PeripheralViewController.refreshScanView), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        super.viewWillAppear(animated)
        print("[log] - viewWillDisappear called")
        viewReloadTimer?.invalidate()
    }
    
    func updateViewForScanning() {
        statusLabel.text = "Scanning BLE Devices ..."
        bluetoothIcon.pulseAnimation()
        bluetoothIcon.isHidden = false
        scannerButton.buttonColorScheme(true)
    }
    
    func updateViewForStopScanning() {
        print("[log] - updateViewForStopScanning called")
        let plural = peripherals.count > 1 ? "s" : ""
        statusLabel.text = "\(peripherals.count) Device\(plural) found"
        bluetoothIcon.layer.removeAllAnimations()
        bluetoothIcon.isHidden = true
        scannerButton.buttonColorScheme(false)
    }
    
    @IBAction func scanningButtonPressed(_ sender: Any) {
        if centralManager!.isScanning {
            centralManager?.stopScan()
            updateViewForStopScanning()
        } else {
            startScanning()
        }
    }

    
    /* Scan for BLE peripheral */
    func startScanning() {
        print("[log] - Scanning...")
        let triggerTime = (Int64(NSEC_PER_SEC)*10) // Nanosec per sec
        peripherals = []    // Contains the devices detected
        
        // Scan devices and add them to the tableView
        self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        updateViewForScanning()
        
        /* Interrupt the scan and update the view after a time deadline */
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime)/Double(NSEC_PER_SEC), execute: { () -> Void in
            if self.centralManager.isScanning {
                self.centralManager.stopScan()
                print(self.peripherals)
                print("[log] - Scan stopped")
                self.updateViewForStopScanning()
            }
        })
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
}



extension PeripheralViewController : CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            print("[log] - Central Manager state = PoweredOn")
            startScanning()
        } else {
            print("[log] - Central Manager state = BLE ERROR")
        }
    }
    
    /* The centralManager has discoered a new BLE peripheral */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // If the peripheral has already been detected, we just update its RSSI value
        for (index, foundPeripheral) in peripherals.enumerated() {
            if foundPeripheral.peripheral?.identifier == peripheral.identifier{
                peripherals[index].lastRSSI = RSSI
                return
            }
        }
        
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, isConnectable: isConnectable)
        peripherals.append(displayPeripheral)
        tableView.reloadData()
    }
}


extension PeripheralViewController : CBPeripheralDelegate {
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[log] - Error connecting peripheral: \(String(describing: error?.localizedDescription))")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[log] - Peripheral connected")
        performSegue(withIdentifier: "PeripheralConnectedSegue", sender: self)
        peripheral.discoverServices(nil)
    }
}

extension PeripheralViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as! DeviceTableViewCell
        
        cell.displayPeripheral = peripherals[indexPath.row]
        cell.delegate = self
        print("[log] - Cell = \(cell)")
            return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
}

extension PeripheralViewController: DeviceCellDelegate {
    
    func connectPressed(_ peripheral: CBPeripheral) {
        if peripheral.state != .connected {
            selectedPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }
}



