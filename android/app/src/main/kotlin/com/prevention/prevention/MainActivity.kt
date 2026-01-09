package com.prevention.prevention

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.prevention/blocker"
    private val VPN_REQUEST_CODE = 0
    private val TAG = "MainActivity"

    companion object {
        private const val PREFS_NAME = "vpn_state"
        private const val KEY_VPN_RUNNING = "is_vpn_running"
        
        fun setVpnRunning(context: Context, running: Boolean) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_VPN_RUNNING, running)
                .apply()
            Log.d("MainActivity", "VPN state saved: $running")
        }
        
        fun isVpnRunning(context: Context): Boolean {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_VPN_RUNNING, false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    Log.d(TAG, "startVpn called")
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        Log.d(TAG, "VPN permission needed, requesting...")
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                        result.success(true)
                    } else {
                        Log.d(TAG, "VPN already authorized, starting service...")
                        startVpnService()
                        result.success(true)
                    }
                }
                "stopVpn" -> {
                    Log.d(TAG, "stopVpn called")
                    val intent = Intent(this, BlockerVpnService::class.java)
                    intent.action = "STOP"
                    startService(intent)
                    setVpnRunning(this, false)
                    result.success(true)
                }
                "isVpnActive" -> {
                    val isActive = isVpnRunning(this)
                    Log.d(TAG, "isVpnActive checked: $isActive")
                    result.success(isActive)
                }
                "checkDevMode" -> {
                    val isDev = TamperDetector.isDevModeEnabled(this)
                    result.success(isDev)
                }
                "isExternalVpnActive" -> {
                    val vpnDetected = NetworkUtils.isVpnActive(this) && !isVpnRunning(this)
                    Log.d(TAG, "External VPN check: $vpnDetected")
                    result.success(vpnDetected)
                }
                "isEmulator" -> {
                    val isEmu = TamperDetector.isEmulator()
                    result.success(isEmu)
                }
                "isRooted" -> {
                    val isRoot = TamperDetector.isRooted()
                    result.success(isRoot)
                }
                "getTamperStatus" -> {
                    val status = TamperDetector.getTamperStatus(this)
                    result.success(status)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVpnService() {
        val intent = Intent(this, BlockerVpnService::class.java)
        startService(intent)
        setVpnRunning(this, true)
        Log.d(TAG, "VPN service started")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                Log.d(TAG, "VPN permission granted")
                startVpnService()
            } else {
                Log.d(TAG, "VPN permission denied")
                setVpnRunning(this, false)
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
