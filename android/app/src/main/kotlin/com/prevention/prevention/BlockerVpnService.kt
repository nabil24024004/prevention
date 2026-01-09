package com.prevention.prevention

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

class BlockerVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val TAG = "BlockerVpnService"
    private val CHANNEL_ID = "prevention_vpn_channel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        // 1. Start as Foreground Service (Fixes persistence)
        startForegroundService()
        
        // 2. Start VPN
        startVpn()
        
        return START_STICKY
    }

    private fun startForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Status",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Prevention is Active")
                .setContentText("Protecting your browser traffic")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .build()
        } else {
            Notification.Builder(this)
                .setContentTitle("Prevention is Active")
                .setContentText("Protecting your browser traffic")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .build()
        }

        startForeground(1, notification)
    }

    private fun startVpn() {
        if (vpnInterface != null) return

        try {
            val builder = Builder()
            
            // Set the VPN interface address
            builder.addAddress("10.0.0.2", 32)
            
            // Route all traffic (but scoped to allowed apps)
            builder.addRoute("0.0.0.0", 0)
            
            // Use Cloudflare Family DNS (Blocks Malware and Adult Content)
            builder.addDnsServer("1.1.1.3") 
            builder.addDnsServer("1.0.0.3")

            // 3. Split Tunneling: ALLOW-LIST only browsers (Fixes blocking other apps)
            val browserPackages = listOf(
                "com.android.chrome",
                "com.chrome.beta",
                "com.chrome.dev",
                "com.google.android.apps.chrome",
                "org.mozilla.firefox",
                "com.sec.android.app.sbrowser",
                "com.microsoft.emmx",
                "com.opera.browser",
                "com.opera.mini.native",
                "com.duckduckgo.mobile.android",
                "com.brave.browser",
                "com.vianet.browser",
                "com.vivaldi.browser"
            )

            var addedAny = false
            for (pkg in browserPackages) {
                try {
                    builder.addAllowedApplication(pkg)
                    addedAny = true
                } catch (e: PackageManager.NameNotFoundException) {
                    // App not installed, skip
                }
            }

            // Fallback: If no browsers found, or if we want to ensure *some* protection,
            // we might want to default to something? 
            // For now, if no browsers are added, the VPN effectively routes nothing (safe fallback).
            
            builder.setSession("Prevention Blocker")

            // Create the interface
            vpnInterface = builder.establish()
            
            Log.i(TAG, "VPN Started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN", e)
            stopSelf()
        }
    }

    private fun stopVpn() {
        try {
            vpnInterface?.close()
            vpnInterface = null
            MainActivity.setVpnRunning(this, false)
            stopForeground(true)
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
