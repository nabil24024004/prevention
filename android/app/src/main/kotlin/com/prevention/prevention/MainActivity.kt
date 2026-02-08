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
        private const val KEY_PANIC_LOCKDOWN = "is_panic_lockdown"
        
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
        
        fun setPanicLockdown(context: Context, active: Boolean) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_PANIC_LOCKDOWN, active)
                .apply()
            Log.d("MainActivity", "Panic lockdown state: $active")
        }
        
        fun isPanicLockdown(context: Context): Boolean {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_PANIC_LOCKDOWN, false)
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
                "setPanicLockdown" -> {
                    val active = call.argument<Boolean>("active") ?: false
                    setPanicLockdown(this, active)
                    Log.d(TAG, "setPanicLockdown called: $active")
                    result.success(true)
                }
                "startScreenPin" -> {
                    // Start screen pinning (task lock) - user will be prompted to confirm
                    Log.d(TAG, "startScreenPin called")
                    try {
                        startLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "startScreenPin failed: ${e.message}")
                        result.error("LOCK_TASK_ERROR", e.message, null)
                    }
                }
                "stopScreenPin" -> {
                    // Stop screen pinning
                    Log.d(TAG, "stopScreenPin called")
                    try {
                        stopLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "stopScreenPin failed: ${e.message}")
                        result.error("UNLOCK_TASK_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVpnService() {
        val intent = Intent(this, BlockerVpnService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
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

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // onUserLeaveHint is called when user presses home button
        // Use Handler with delay to bring app back after system processes the home action
        if (isPanicLockdown(this)) {
            Log.d(TAG, "Panic lockdown active - blocking home button")
            android.os.Handler(mainLooper).postDelayed({
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
                activityManager.moveTaskToFront(taskId, android.app.ActivityManager.MOVE_TASK_WITH_HOME)
                Log.d(TAG, "Brought app back to foreground")
            }, 100) // Small delay to let system process first
        }
    }

    override fun onBackPressed() {
        // Block back button during panic lockdown
        if (isPanicLockdown(this)) {
            Log.d(TAG, "Panic lockdown active - blocking back button")
            return // Do nothing
        }
        super.onBackPressed()
    }
}
