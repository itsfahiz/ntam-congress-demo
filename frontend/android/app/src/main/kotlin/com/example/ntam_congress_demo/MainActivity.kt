package com.example.ntam_congress_demo

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "ntam.congress/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val filename = call.argument<String>("filename")
            val mimeType = call.argument<String>("mimeType")
            val bytes = call.argument<ByteArray>("bytes")
            if (filename.isNullOrBlank() || mimeType.isNullOrBlank() ||
                bytes == null || bytes.isEmpty() ||
                filename.contains("/") || filename.contains("\\") ||
                !filename.matches(Regex("[A-Za-z0-9._-]{1,120}"))) {
                result.error("INVALID_FILE", "Invalid download details.", null)
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                result.error(
                    "EXPORT_REQUIRED",
                    "On Android 9 or earlier, use Export and Save to Files.",
                    null
                )
                return@setMethodCallHandler
            }

            // Android 10+: MediaStore creates a visible file in Downloads
            // without broad file-system permissions or MANAGE_EXTERNAL_STORAGE.
            var uri: android.net.Uri? = null
            try {
                val resolver = applicationContext.contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(
                        MediaStore.MediaColumns.RELATIVE_PATH,
                        Environment.DIRECTORY_DOWNLOADS + "/NTAM Congress"
                    )
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("Cannot create download file.")
                resolver.openOutputStream(uri)?.use { stream ->
                    stream.write(bytes)
                    stream.flush()
                } ?: throw IllegalStateException("Cannot open download file.")
                resolver.update(uri, ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                }, null, null)
                result.success("Downloads/NTAM Congress/$filename")
            } catch (error: Exception) {
                uri?.let { applicationContext.contentResolver.delete(it, null, null) }
                result.error("DOWNLOAD_FAILED", "Could not save to Downloads.", null)
            }
        }
    }
}
