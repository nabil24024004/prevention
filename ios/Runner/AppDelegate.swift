import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.example.prevention/blocker"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        let blockerChannel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )
        
        blockerChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "startVpn":
                self?.startVPN(result: result)
            case "stopVpn":
                self?.stopVPN(result: result)
            case "isVpnActive":
                self?.checkVPNStatus(result: result)
            case "isRooted":
                result(TamperDetector.isJailbroken())
            case "isEmulator":
                result(TamperDetector.isSimulator())
            case "checkDevMode":
                result(false) // Not available on iOS
            case "isExternalVpnActive":
                self?.checkExternalVPN(result: result)
            case "getTamperStatus":
                result(TamperDetector.getTamperStatus())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - VPN Management
    
    private func startVPN(result: @escaping FlutterResult) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                print("Error loading VPN preferences: \(error)")
                result(false)
                return
            }
            
            let manager = managers?.first ?? NETunnelProviderManager()
            
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.prevention.prevention.PacketTunnel"
            proto.serverAddress = "Cloudflare Family DNS"
            
            manager.protocolConfiguration = proto
            manager.localizedDescription = "Prevention Browser Protection"
            manager.isEnabled = true
            
            manager.saveToPreferences { error in
                if let error = error {
                    print("Error saving VPN preferences: \(error)")
                    result(false)
                    return
                }
                
                // Reload after saving
                manager.loadFromPreferences { error in
                    if let error = error {
                        print("Error reloading VPN preferences: \(error)")
                        result(false)
                        return
                    }
                    
                    do {
                        try manager.connection.startVPNTunnel()
                        print("VPN tunnel started successfully")
                        result(true)
                    } catch {
                        print("Error starting VPN tunnel: \(error)")
                        result(false)
                    }
                }
            }
        }
    }
    
    private func stopVPN(result: @escaping FlutterResult) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                print("Error loading VPN preferences: \(error)")
                result(false)
                return
            }
            
            guard let manager = managers?.first else {
                result(true) // No VPN configured, consider it stopped
                return
            }
            
            manager.connection.stopVPNTunnel()
            print("VPN tunnel stopped")
            result(true)
        }
    }
    
    private func checkVPNStatus(result: @escaping FlutterResult) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if error != nil || managers?.isEmpty ?? true {
                result(false)
                return
            }
            
            let status = managers?.first?.connection.status
            let isActive = status == .connected || status == .connecting
            result(isActive)
        }
    }
    
    private func checkExternalVPN(result: @escaping FlutterResult) {
        // Check if any VPN is active that's not ours
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if error != nil {
                result(false)
                return
            }
            
            // Check system VPN status
            let cfDict = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
            if let dict = cfDict as? [String: Any] {
                if let scoped = dict["__SCOPED__"] as? [String: Any] {
                    // Check for VPN interfaces (utun, ppp, ipsec)
                    for key in scoped.keys {
                        if key.hasPrefix("utun") || key.hasPrefix("ppp") || key.hasPrefix("ipsec") {
                            // VPN detected, check if it's ours
                            let ourStatus = managers?.first?.connection.status
                            if ourStatus != .connected && ourStatus != .connecting {
                                result(true) // External VPN detected
                                return
                            }
                        }
                    }
                }
            }
            result(false)
        }
    }
}
