package com.quicksave.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground-сервис для скачивания больших файлов в фоне.
 *
 * Пока идёт загрузка (диапазон байт пишется Dart-слоем через Dio),
 * этот сервис держит процесс живым через ongoing-уведомление.
 * На Android 14+ использует foregroundServiceType=dataSync
 * (разрешение FOREGROUND_SERVICE_DATA_SYNC объявлено в манифесте).
 *
 * Управляется из Flutter через MethodChannel "quicksave/download_fg"
 * (см. MainActivity): start / progress / stop.
 */
class DownloadForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        ensureChannel(this)
        startForegroundCompat(buildNotification(this, 0))
        return START_NOT_STICKY
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceCompat.startForeground(
                this,
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    companion object {
        private const val NOTIF_ID = 7701
        private const val CHANNEL_ID = "quicksave_download_fg"
        private const val ACTION_STOP = "com.quicksave.app.FG_STOP"

        fun start(context: Context) {
            val intent = Intent(context, DownloadForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun updateProgress(context: Context, percent: Int) {
            ensureChannel(context)
            try {
                NotificationManagerCompat.from(context)
                    .notify(NOTIF_ID, buildNotification(context, percent))
            } catch (_: SecurityException) {
                // POST_NOTIFICATIONS не выдано на Android 13+ — прогресс не виден,
                // но foreground-сервис продолжает работать.
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, DownloadForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {
                // сервис не был запущен — ничего не делаем
            }
        }

        fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val mgr = context.getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                if (mgr.getNotificationChannel(CHANNEL_ID) == null) {
                    val ch = NotificationChannel(
                        CHANNEL_ID,
                        "Загрузка видео",
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = "Прогресс скачивания видео"
                        setShowBadge(false)
                    }
                    mgr.createNotificationChannel(ch)
                }
            }
        }

        fun buildNotification(context: Context, percent: Int): Notification {
            val p = percent.coerceIn(0, 100)
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle("QuickSave")
                .setContentText("Скачивание видео… $p%")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setProgress(100, p, false)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        }
    }
}
