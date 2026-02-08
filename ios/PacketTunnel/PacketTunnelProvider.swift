import NetworkExtension

/// PacketTunnelProvider - iOS equivalent of Android's BlockerVpnService.kt
/// Creates a local VPN tunnel that routes DNS through Cloudflare Family DNS (1.1.1.3)
/// to block adult content at the DNS level
class PacketTunnelProvider: NEPacketTunnelProvider {
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("Prevention: Starting packet tunnel...")
        
        // Configure tunnel network settings
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.0.1")
        
        // Configure DNS to Cloudflare Family DNS (blocks adult content)
        // Same DNS servers as Android: 1.1.1.3 and 1.0.0.3
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.3", "1.0.0.3"])
        dnsSettings.matchDomains = [""] // Match all domains
        settings.dnsSettings = dnsSettings
        
        // IPv4 configuration
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        // Note: We don't add includedRoutes to avoid routing all traffic
        // We only want DNS to go through our tunnel
        settings.ipv4Settings = ipv4Settings
        
        // MTU setting
        settings.mtu = 1400
        
        // Apply the settings
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                NSLog("Prevention: Failed to set tunnel settings: \(error)")
                completionHandler(error)
                return
            }
            
            NSLog("Prevention: Tunnel started successfully with Cloudflare Family DNS")
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("Prevention: Stopping tunnel with reason: \(reason)")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Handle messages from the main app if needed
        NSLog("Prevention: Received app message")
        completionHandler?(nil)
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        NSLog("Prevention: Tunnel going to sleep")
        completionHandler()
    }
    
    override func wake() {
        NSLog("Prevention: Tunnel waking up")
    }
}
