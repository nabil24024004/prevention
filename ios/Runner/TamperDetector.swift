import Foundation
import UIKit

/// TamperDetector - iOS equivalent of Android's TamperDetector.kt
/// Provides jailbreak and simulator detection for security enforcement
class TamperDetector {
    
    /// Detects if running on iOS Simulator
    static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// Detects if device is jailbroken (best effort)
    /// Uses multiple heuristics for comprehensive detection
    static func isJailbroken() -> Bool {
        // Check 1: Common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/cycript",
            "/private/var/tmp/cydia.log",
            "/Applications/Icy.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Applications/blackra1n.app",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check 2: Can write to restricted paths
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // Should not be able to write here
        } catch {
            // Expected to fail on non-jailbroken devices
        }
        
        // Check 3: Can open Cydia URL scheme
        if let url = URL(string: "cydia://package/com.example.package") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        
        // Check 4: Check for symbolic links in system paths
        do {
            let systemPath = "/Applications"
            let attributes = try FileManager.default.attributesOfItem(atPath: systemPath)
            if let type = attributes[.type] as? FileAttributeType, type == .typeSymbolicLink {
                return true
            }
        } catch {
            // Expected
        }
        
        return false
    }
    
    /// Comprehensive tamper check - returns all status indicators
    static func getTamperStatus() -> [String: Bool] {
        return [
            "jailbroken": isJailbroken(),
            "simulator": isSimulator(),
            "dev_mode": false // Not available on iOS
        ]
    }
}
