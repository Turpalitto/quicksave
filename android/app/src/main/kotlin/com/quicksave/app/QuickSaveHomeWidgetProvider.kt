package com.quicksave.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class QuickSaveHomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.home_widget)
        val launchIntent = buildLaunchIntent(context)
        val pending = PendingIntent.getActivity(
            context,
            widgetId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pending)
        manager.updateAppWidget(widgetId, views)
    }

    private fun buildLaunchIntent(context: Context): Intent {
        return Intent(context, MainActivity::class.java).apply {
            action = ACTION_WIDGET
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            readClipboardText(context)?.let { putExtra(Intent.EXTRA_TEXT, it) }
        }
    }

    private fun readClipboardText(context: Context): String? {
        val clipboard =
            context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                ?: return null
        if (!clipboard.hasPrimaryClip()) return null
        val clip = clipboard.primaryClip ?: return null
        if (clip.description.hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN)) {
            val text = clip.getItemAt(0).coerceToText(context)?.toString()?.trim()
            if (!text.isNullOrEmpty()) return text
        }
        return null
    }

    companion object {
        const val ACTION_WIDGET = "com.quicksave.app.ACTION_HOME_WIDGET"

        fun requestUpdate(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val cn = ComponentName(context, QuickSaveHomeWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(cn)
            if (ids.isEmpty()) return
            val intent = Intent(context, QuickSaveHomeWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
