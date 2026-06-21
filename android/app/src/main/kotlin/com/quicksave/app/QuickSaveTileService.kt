package com.quicksave.app

import android.app.PendingIntent
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tile: opens QuickSave and passes clipboard text when available.
 */
class QuickSaveTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = getString(R.string.tile_label)
            contentDescription = getString(R.string.tile_description)
            updateTile()
        }
    }

    override fun onClick() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_QS_TILE
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            readClipboardText()?.let { putExtra(Intent.EXTRA_TEXT, it) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(launchIntent)
        }
    }

    private fun readClipboardText(): String? {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
            ?: return null
        if (!clipboard.hasPrimaryClip()) return null
        val clip = clipboard.primaryClip ?: return null
        if (clip.description.hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN)) {
            val text = clip.getItemAt(0).coerceToText(this)?.toString()?.trim()
            if (!text.isNullOrEmpty()) return text
        }
        return null
    }

    companion object {
        const val ACTION_QS_TILE = "com.quicksave.app.ACTION_QS_TILE"
    }
}
