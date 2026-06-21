package com.quicksave.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "quicksave/share_intent"
    private val fgChannelName = "quicksave/download_fg"
    private val galleryChannelName = "quicksave/gallery"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )

        // Если приложение уже запущено и пользователь поделился ссылкой,
        // onNewIntent() вызовет этот канал снова.
        handleIntent(intent)

        // MethodChannel для управления foreground-сервисом скачивания.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            fgChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    DownloadForegroundService.start(this)
                    result.success(null)
                }
                "progress" -> {
                    val percent = call.argument<Int>("percent") ?: 0
                    DownloadForegroundService.updateProgress(this, percent)
                    result.success(null)
                }
                "stop" -> {
                    DownloadForegroundService.stop(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            galleryChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToGallery" -> {
                    val path = call.argument<String>("path")
                    val isVideo = call.argument<Boolean>("isVideo") ?: false
                    if (path.isNullOrBlank()) {
                        result.error("invalid", "path required", null)
                    } else {
                        val uri = GalleryHelper.saveToGallery(this, path, isVideo)
                        result.success(uri)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // initial intent тоже обработается в configureFlutterEngine()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        val type = intent.type

        val sharedText = when {
            Intent.ACTION_SEND == action && type == "text/plain" ->
                intent.getStringExtra(Intent.EXTRA_TEXT)
            QuickSaveTileService.ACTION_QS_TILE == action ->
                intent.getStringExtra(Intent.EXTRA_TEXT)
            QuickSaveHomeWidgetProvider.ACTION_WIDGET == action ->
                intent.getStringExtra(Intent.EXTRA_TEXT)
            else -> null
        }

        if (!sharedText.isNullOrBlank()) {
            methodChannel?.invokeMethod("onSharedText", sharedText)
        }
    }
}
