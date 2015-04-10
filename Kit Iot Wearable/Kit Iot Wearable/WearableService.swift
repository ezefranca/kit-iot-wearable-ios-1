//
//  WearableService.swift
//  kit-iot-wearable
//
//  Created by Vitor Leal on 4/1/15.
//  Copyright (c) 2015 Telefonica VIVO. All rights reserved.
//
import Foundation
import CoreBluetooth


let ServiceUUID = CBUUID(string: "FFE0")
let CharacteristicUIID = CBUUID(string: "FFE1")
let WearableServiceChangedStatusNotification = "WearableServiceChangedStatusNotification"


class WearableService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var peripheralCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()

        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    // Start discovering services
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([ServiceUUID])
    }
    
    // Reset
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        self.sendWearableServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Look for bluetooth with the service FFEO
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        let uuidsForBTService: [CBUUID] = [CharacteristicUIID]
        
        if (peripheral != self.peripheral || error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services.count == 0)) {
            return
        }
        
        // Find characteristics
        for service in peripheral.services {
            if service.UUID == ServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as CBService)
            }
        }
    }
    
    // Look for the bluetooth characteristics
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (peripheral != self.peripheral || error != nil) {
            return
        }
        
        for characteristic in service.characteristics {
            if characteristic.UUID == CharacteristicUIID {
                self.peripheralCharacteristic = (characteristic as CBCharacteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                
                self.sendWearableServiceNotificationWithIsBluetoothConnected(true)
            }
        }
    }
    
    // Send command
    func sendCommand(command: NSString) {
        let str = NSString(string: command)
        let data = NSData(bytes: str.UTF8String, length: str.length)
        
        self.peripheral?.writeValue(data, forCharacteristic: self.peripheralCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
    // Send wearable connected notification
    func sendWearableServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]

        NSNotificationCenter.defaultCenter().postNotificationName(WearableServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
}