package com.quicksave.app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream

object GalleryHelper {
    fun saveToGallery(context: android.content.Context, path: String, isVideo: Boolean): String? {
        val file = File(path)
        if (!file.exists()) return null

        val mime = if (isVideo) "video/mp4" else guessImageMime(file.name)
        val relativePath = if (isVideo) {
            "${Environment.DIRECTORY_MOVIES}/QuickSave"
        } else {
            "${Environment.DIRECTORY_PICTURES}/QuickSave"
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val collection = if (isVideo) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }

        val resolver = context.contentResolver
        val uri = resolver.insert(collection, values) ?: return null

        resolver.openOutputStream(uri)?.use { out ->
            FileInputStream(file).use { input -> input.copyTo(out) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }

        return uri.toString()
    }

    private fun guessImageMime(name: String): String = when {
        name.endsWith(".png", ignoreCase = true) -> "image/png"
        name.endsWith(".webp", ignoreCase = true) -> "image/webp"
        else -> "image/jpeg"
    }
}
