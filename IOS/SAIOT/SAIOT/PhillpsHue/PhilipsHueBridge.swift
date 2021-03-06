//
//  PhilipsHueBridge.swift
//  SAIOT
//
//  Created by 양창엽 on 2018. 4. 18..
//  Copyright © 2018년 Yang-Chang-Yeop. All rights reserved.
//

import Gloss
import SwiftyHue

final class PhilipsHueBridge: NSObject {
    
    // MARK: - Variable
    private var bridgeAccessConfigKey = "HUE_BRIDGE_KEY"
    fileprivate var hueBridge: HueBridge?
    fileprivate var swiftyHue: SwiftyHue = SwiftyHue()
    fileprivate var hueBridgeFinder: BridgeFinder = BridgeFinder()
    fileprivate var hueAuthenticator: BridgeAuthenticator?
    internal static var hueInstance: PhilipsHueBridge = PhilipsHueBridge()
    
    // MARK: - Init
    private override init() {}
    
    // MARK: - Method
    internal func getHueBridgeConfig() -> String {
        
        if connectHueBridge(), let bridgeConfig: BridgeConfiguration = swiftyHue.resourceCache?.bridgeConfiguration {
            return "- IP: \(bridgeConfig.ipaddress!)\n- MAC: \(bridgeConfig.mac)"
        }
        
        return "휴가 연결되어 있지 않아요."
    }
    internal func connectHueBridge() -> Bool {
        
        if let bridgeAccessConfig: BridgeAccessConfig = readHueBridgeAccessConfig() {
            swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .lights)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .groups)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .rules)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .scenes)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .schedules)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .sensors)
            swiftyHue.setLocalHeartbeatInterval(10, forResourceType: .config)
            swiftyHue.startHeartbeat()
            return true
        }
        
        hueBridgeFinder.delegate = self
        hueBridgeFinder.start()
        return false
    }
    internal func changeHueColor(red: Int, green: Int, blue: Int, alpha: Int) {
        guard let lights = swiftyHue.resourceCache?.lights else {
            print("Error, Not Load the philips hue lights.")
            return
        }
        
        // Change Light Color State loop
        for light in lights {
            let colorXY = HueUtilities.calculateXY(UIColor.init(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha)), forModel: light.key)
            
            var lightState: LightState = LightState()
            lightState.brightness = alpha
            lightState.xy = [Float(colorXY.x), Float(colorXY.y)]
            
            swiftyHue.bridgeSendAPI.updateLightStateForId(light.key, withLightState: lightState, completionHandler: { error in
                print("Error, Not Change the philips hue light color. \(String(describing: error))")
            })
        }
    }
    internal func changeHuePower(power: Bool) {
        
        guard let lights = swiftyHue.resourceCache?.lights else {
            print("Error, Not Load the Philips Hue Lights.")
            return
        }
        
        for light in lights {
            var lightState: LightState = LightState()
            lightState.on = power
            
            swiftyHue.bridgeSendAPI.updateLightStateForId(light.key, withLightState: lightState, completionHandler: { error in
                print("Error, Not Change the Philips hue light Power. \(String(describing: error))")
            })
        }
    }
    private func readHueBridgeAccessConfig() -> BridgeAccessConfig?
    {
        let userDefaults: UserDefaults = UserDefaults.standard
        if let bridgeAccessConfigJSON = userDefaults.object(forKey: bridgeAccessConfigKey) as? JSON {
            return BridgeAccessConfig(json: bridgeAccessConfigJSON)
        }
        
        return nil
    }
    private func writeHueBridgeAccessConfig(bridgeAccessConfig: BridgeAccessConfig) {
        let userDefaults = UserDefaults.standard
        if let bridgeAccessConfigJSON: JSON = bridgeAccessConfig.toJSON() {
            userDefaults.set(bridgeAccessConfigJSON, forKey: bridgeAccessConfigKey)
            print("- Export philips hue bridge config.")
        }
    }
}

// MARK: - BridgeFinderDelegate Extension
extension PhilipsHueBridge: BridgeFinderDelegate {
    
    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {
        if let bridge: HueBridge = bridges.first {
            
            hueBridge = bridge
            print("Bridge IP: \(bridge.ip), Bridge NAME: \(bridge.modelName), Bridge Serial: \(bridge.serialNumber)")
            
            // Philips Hue Bridge Authenticator
            hueAuthenticator = BridgeAuthenticator(bridge: bridge, uniqueIdentifier: bridge.serialNumber)
            hueAuthenticator?.delegate = self
            hueAuthenticator?.start()
        }
    }
}

// MAKR: - BridgeAuthenticatorDelegate Extension
extension PhilipsHueBridge: BridgeAuthenticatorDelegate {
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        
        if let bridge: HueBridge = hueBridge {
            let bridgeConfig = BridgeAccessConfig(bridgeId: bridge.modelName, ipAddress: bridge.ip, username: username)
            swiftyHue.setBridgeAccessConfig(bridgeConfig)
            
            writeHueBridgeAccessConfig(bridgeAccessConfig: bridgeConfig)
            print("- Connect philips hue bridge. \(bridgeConfig.ipAddress):\(bridgeConfig.username):\(bridgeConfig.bridgeId)")
        }
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        print("- Philips Hue Bridge Authenticator Error: \(error)")
    }
    
    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {}
    
    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {}
}
