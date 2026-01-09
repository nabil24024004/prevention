package com.prevention.prevention

import android.content.Context
import android.os.Build
import android.provider.Settings
import java.io.File

object TamperDetector {
    
    /**
     * Checks if Developer Mode is enabled on Android
     */
    fun isDevModeEnabled(context: Context): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
        ) == 1
    }
    
    /**
     * Detects if running on an emulator
     * Uses multiple heuristics for comprehensive detection
     */
    fun isEmulator(): Boolean {
        // Check 1: Known emulator fingerprints
        if (Build.FINGERPRINT.contains("generic") ||
            Build.FINGERPRINT.startsWith("unknown") ||
            Build.MODEL.contains("google_sdk") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for x86") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
            "google_sdk" == Build.PRODUCT
        ) {
            return true
        }
        
        // Check 2: Hardware characteristics
        if (Build.HARDWARE.contains("goldfish") ||
            Build.HARDWARE.contains("ranchu")
        ) {
            return true
        }
        
        // Check 3: Known emulator files
        val emulatorFiles = arrayOf(
            "/dev/socket/qemud",
            "/dev/qemu_pipe",
            "/system/lib/libc_malloc_debug_qemu.so",
            "/sys/qemu_trace",
            "/system/bin/qemu-props"
        )
        
        return emulatorFiles.any { File(it).exists() }
    }
    
    /**
     * Detects if device is rooted
     * Checks for common root indicators
     */
    fun isRooted(): Boolean {
        // Check 1: Test-Keys in build tags
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            return true
        }
        
        // Check 2: Common root binaries
        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        
        if (rootPaths.any { File(it).exists() }) {
            return true
        }
        
        // Check 3: Try to execute su command
        return canExecuteCommand("/system/xbin/which su") ||
               canExecuteCommand("/system/bin/which su") ||
               canExecuteCommand("which su")
    }
    
    /**
     * Helper: Check if a command can be executed
     */
    private fun canExecuteCommand(command: String): Boolean {
        return try {
            Runtime.getRuntime().exec(command)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Detects if app is running in debug mode
     */
    fun isDebugBuild(context: Context): Boolean {
        return (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }
    
    /**
     * Comprehensive tamper check
     * Returns a map of all tamper indicators
     */
    fun getTamperStatus(context: Context): Map<String, Boolean> {
        return mapOf(
            "dev_mode" to isDevModeEnabled(context),
            "emulator" to isEmulator(),
            "rooted" to isRooted(),
            "debug_build" to isDebugBuild(context)
        )
    }
}
