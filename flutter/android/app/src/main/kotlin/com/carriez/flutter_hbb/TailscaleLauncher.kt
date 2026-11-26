// SPDX-License-Identifier: AGPL-3.0-only
package com.carriez.flutter_hbb

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.util.Log
import java.net.Inet4Address

object TailscaleLauncher {
    private const val PACKAGE = "com.tailscale.ipn"

    fun open(activity: Activity): Boolean {
        return try {
            val intent = activity.packageManager.getLaunchIntentForPackage(PACKAGE) ?: return false
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.w("TailscaleLauncher", "Unable to open Tailscale", e)
            false
        }
    }

    fun connect(activity: Activity): Boolean {
        when (vpnStatus(activity)) {
            "cgnat-vpn" -> return true
            "none" -> Unit
            else -> return false
        }
        return try {
            val intent = Intent("com.tailscale.ipn.CONNECT_VPN").setPackage(PACKAGE)
            if (intent.resolveActivity(activity.packageManager) == null) return open(activity)
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.w("TailscaleLauncher", "Unable to request Tailscale connection", e)
            open(activity)
        }
    }

    fun vpnStatus(context: Context): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return "unknown"
        return try {
            val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val activeNetwork = manager.activeNetwork
            val activeVpn = activeNetwork != null &&
                manager.getNetworkCapabilities(activeNetwork)?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
            val hasTailscaleRangeAddress = activeVpn &&
                manager.getLinkProperties(activeNetwork)?.linkAddresses?.any {
                    val address = it.address
                    if (address !is Inet4Address) return@any false
                    val bytes = address.address
                    (bytes[0].toInt() and 0xff) == 100 &&
                        (bytes[1].toInt() and 0xff) in 64..127
                } == true
            val anyVpn = manager.allNetworks.any {
                manager.getNetworkCapabilities(it)?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
            }
            when {
                hasTailscaleRangeAddress -> "cgnat-vpn"
                anyVpn -> "other-vpn"
                else -> "none"
            }
        } catch (e: Exception) {
            Log.w("TailscaleLauncher", "Unable to inspect VPN state", e)
            "unknown"
        }
    }
}
