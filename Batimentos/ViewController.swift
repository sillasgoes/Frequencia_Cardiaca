//
//  ViewController.swift
//  Batimentos
//
//  Created by Evo Systems on 02/03/22.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    var peripheralConnected: CBPeripheral!
    var heartRate = "180D"
    var heartSensor = "2A38"
    
    @IBOutlet weak var heartTextField: UITextField!
    @IBOutlet weak var nameHeartLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
    }
    
    
    
}


extension ViewController: CBPeripheralDelegate, CBCentralManagerDelegate{
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [CBUUID(string: "180D")], options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        break
        case .poweredOff:
            print("Bluetooth desligado")
        break
        default:
            print("Outro estado do Bluetooth")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheralConnected = peripheral
        peripheralConnected.delegate = self
        centralManager.connect(peripheralConnected)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheralConnected.discoverServices(nil)
        centralManager.stopScan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let services = peripheral.services {
            
            for servico in services {
                switch servico.uuid.uuidString{
                case heartRate:
                    print("Encontrei o \(heartRate)")
                    peripheral.discoverCharacteristics(nil, for: servico)
                break
                default:
                print("Serviço de: \(servico)")
                    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characterists = service.characteristics else {return}
        for characteristic in characterists {
            
            if characteristic.properties.contains(.read) {
              print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
              print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
      guard let characteristicData = characteristic.value else { return -1 }
      let byteArray = [UInt8](characteristicData)

      let firstBitValue = byteArray[0] & 0x01
      if firstBitValue == 0 {
        // Heart Rate Value Format is in the 2nd byte
        return Int(byteArray[1])
      } else {
        // Heart Rate Value Format is in the 2nd and 3rd bytes
        return (Int(byteArray[1]) << 8) + Int(byteArray[2])
      }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        switch characteristic.uuid.uuidString {
        case "2A37":
            let valor = heartRate(from: characteristic)
            heartTextField.text = String(valor)
        break
            
        default:
            print("Não encontrado")
        }
    }
    
    
}
