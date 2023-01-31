//
//  ViewController.swift
//  FlutterDemo
//
//  Created by 马冰垒 on 2023/1/30.
//

import UIKit
import Flutter

class ViewController: UIViewController {
    
    @IBAction func pushAction(_ sender: UIButton) {
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
        let flutterVC = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        // FlutterMethodChannel 为平台通道
        let channel = FlutterMethodChannel(name: "samples.flutter.dev/battery", binaryMessenger: flutterVC.binaryMessenger)
        channel.setMethodCallHandler { [weak self] call, result in
            // Flutter 调用原生回调
            debugPrint("handle flutter messages", call.method)
            if call.method == "getBatteryLevel" {
                self?.receiveBatteryLevel(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        self.present(flutterVC, animated: true)
    }
    
    // MARK: -- Flutter 调用 原生 --
    private func receiveBatteryLevel(result: FlutterResult) {
      let device = UIDevice.current
      device.isBatteryMonitoringEnabled = true
      if device.batteryState == UIDevice.BatteryState.unknown {
        result(FlutterError(code: "UNAVAILABLE",
                            message: "Battery level not available.",
                            details: nil))
      } else {
        result(Int(device.batteryLevel * 100))
      }
    }
}

