package com.lucapaganin.mirai_cook

import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android side of two adapters:
 * - `mirai_cook/share`: forwards text shared via ACTION_SEND to Dart (IMP-1).
 * - `mirai_cook/export`: sends a shopping list note to another app, e.g.
 *   Google Keep, or to the share sheet (EXP-1, EXP-3).
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        initialText = sharedText(intent)
        channel = MethodChannel(messenger, SHARE_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialText" -> {
                        result.success(initialText)
                        initialText = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(messenger, EXPORT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> result.success(
                    shareText(
                        title = call.argument<String>("title") ?: "",
                        text = call.argument<String>("text") ?: "",
                        targetPackage = call.argument<String>("package"),
                    )
                )
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sharedText(intent)?.let { channel?.invokeMethod("sharedText", it) }
    }

    private fun sharedText(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            intent.getStringExtra(Intent.EXTRA_TEXT)
        } else {
            null
        }

    /**
     * Returns "done", or "not_installed" when [targetPackage] cannot handle
     * the intent. Without a target package, opens the share sheet.
     */
    private fun shareText(title: String, text: String, targetPackage: String?): String {
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, title)
            putExtra(Intent.EXTRA_TITLE, title)
            putExtra(Intent.EXTRA_TEXT, text)
        }
        if (targetPackage == null) {
            startActivity(Intent.createChooser(send, title))
            return "done"
        }
        send.setPackage(targetPackage)
        return try {
            startActivity(send)
            "done"
        } catch (e: ActivityNotFoundException) {
            "not_installed"
        }
    }

    companion object {
        private const val SHARE_CHANNEL = "mirai_cook/share"
        private const val EXPORT_CHANNEL = "mirai_cook/export"
    }
}
