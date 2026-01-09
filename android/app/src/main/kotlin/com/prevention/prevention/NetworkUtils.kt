package com.prevention.prevention

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import java.net.NetworkInterface

object NetworkUtils {
    
    /**
     * Detects if device is using ANY VPN connection (not just ours)
     * Returns true if VPN is active
     */
    fun isVpnActive(context: Context): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Modern approach (API 23+)
            val activeNetwork: Network? = connectivityManager.activeNetwork
            val capabilities = activeNetwork?.let { connectivityManager.getNetworkCapabilities(it) }
            capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) ?: false
        } else {
            // Fallback for older versions
            isVpnActiveLegacy()
        }
    }
    
    /**
     * Legacy VPN detection for Android < 6.0
     * Checks network interfaces for VPN adapters
     */
    private fun isVpnActiveLegacy(): Boolean {
        try {
            val networkInterfaces = NetworkInterface.getNetworkInterfaces()
            while (networkInterfaces.hasMoreElements()) {
                val networkInterface = networkInterfaces.nextElement()
                val name = networkInterface.name.lowercase()
                
                // Check for common VPN interface names
                if (name.contains("tun") || name.contains("ppp") || name.contains("pptp")) {
                    return true
                }
            }
        } catch (e: Exception) {
            // If we can't determine, assume no VPN for safety
            return false
        }
        return false
    }
    
    /**
     * Checks if device is using a DNS server different from our Cloudflare setup
     * This can indicate VPN override attempts
     */
    fun isUsingCustomDns(context: Context): Boolean {
        try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val activeNetwork = connectivityManager.activeNetwork ?: return false
                val linkProperties = connectivityManager.getLinkProperties(activeNetwork) ?: return false
                
                val dnsServers = linkProperties.dnsServers
                
                // Check if DNS is NOT our Cloudflare Family DNS
                val expectedDns = listOf("1.1.1.3", "1.0.0.3")
                return dnsServers.none { it.hostAddress in expectedDns }
            }
        } catch (e: Exception) {
            // If detection fails, don't block
            return false
        }
        return false
    }
}
