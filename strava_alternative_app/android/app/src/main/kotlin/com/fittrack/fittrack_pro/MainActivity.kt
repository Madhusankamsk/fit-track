package com.fittrack.fittrack_pro

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        createNotificationChannels()
        super.onCreate(savedInstanceState)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val channels = listOf(
            Triple("Activity Tracking", "Activity Tracking", "GPS activity tracking in progress"),
            Triple("FOREGROUND_DEFAULT", "Background Service", "Executing process in background"),
            Triple("fittrack_tracking", "Activity Tracking", "GPS activity tracking in progress"),
        )
        for ((id, name, description) in channels) {
            val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_LOW)
            channel.description = description
            manager.createNotificationChannel(channel)
        }
    }
}
