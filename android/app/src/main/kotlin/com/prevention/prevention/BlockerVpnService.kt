package com.prevention.prevention

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class BlockerVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val TAG = "BlockerVpnService"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        startVpn()
        return START_STICKY
    }

    private fun startVpn() {
        if (vpnInterface != null) return

        try {
            val builder = Builder()
            
            // Set the VPN interface address
            builder.addAddress("10.0.0.2", 32)
            
            // Route all traffic through the VPN
            builder.addRoute("0.0.0.0", 0)
            
            // Use Cloudflare Family DNS (Blocks Malware and Adult Content)
            builder.addDnsServer("1.1.1.3") 
            builder.addDnsServer("1.0.0.3")

            // Exclude our own app from VPN so Supabase can connect
            builder.addDisallowedApplication(packageName)

            // Set session name
            builder.setSession("Prevention Blocker")

            // Create the interface
            vpnInterface = builder.establish()
            
            Log.i(TAG, "VPN Started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN", e)
        }
    }

    private fun stopVpn() {
        try {
            vpnInterface?.close()
            vpnInterface = null
            MainActivity.setVpnRunning(this, false)
            stopSelf()
            Log.i(TAG, "VPN Stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }
}
