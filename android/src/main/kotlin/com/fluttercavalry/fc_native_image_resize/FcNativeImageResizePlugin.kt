package com.fluttercavalry.fc_native_image_resize

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageDecoder
import androidx.core.net.toUri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMethodCodec
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

/** FcNativeImageResizePlugin */
class FcNativeImageResizePlugin :
    FlutterPlugin,
    MethodCallHandler {
    // / The MethodChannel that will the communication between Flutter and native Android
    // /
    // / This local reference serves to register the plugin with the Flutter Engine and unregister it
    // / when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var mContext: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(
                flutterPluginBinding.binaryMessenger,
                "fc_native_image_resize",
                StandardMethodCodec.INSTANCE,
                flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue(),
            )
        channel.setMethodCallHandler(this)
        mContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            "resizeFile", "resizeFileToBytes" -> {
                try {
                    val data = resizeToBytes(call, mContext)
                    if (call.method == "resizeFile") {
                        FileOutputStream(requireNotNull(call.argument<String>("destFile"))).use { it.write(data) }
                        result.success(null)
                    } else {
                        result.success(data)
                    }
                } catch (err: FailedToDecodeImageFileException) {
                    result.error("FailedToDecodeImageFile", err.message, null)
                } catch (err: Exception) {
                    result.error("PluginError", err.message, null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    internal fun resizeToBytes(
        call: MethodCall,
        context: Context,
    ): ByteArray {
        val srcFile = requireNotNull(call.argument<String>("srcFile"))
        val width = requireNotNull(call.argument<Int>("width"))
        val height = requireNotNull(call.argument<Int>("height"))
        val keepAspectRatio = requireNotNull(call.argument<Boolean>("keepAspectRatio"))
        val type = requireNotNull(call.argument<String>("type"))
        val quality = call.argument<Int>("quality") ?: 90
        require(width != 0 && height != 0 && width >= -1 && height >= -1)
        require(width > 0 || height > 0)
        require(keepAspectRatio || (width > 0 && height > 0))
        require(type == "png" || type == "jpeg")
        require(quality in 1..100)
        val srcUri = call.argument<Boolean>("srcFileUri") ?: false
        val bitmap =
            try {
                val source =
                    if (srcUri) {
                        ImageDecoder.createSource(context.contentResolver, srcFile.toUri())
                    } else {
                        ImageDecoder.createSource(File(srcFile))
                    }
                ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
                    decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                    val newSize =
                        if (keepAspectRatio) {
                            sizeToFit(info.size.width, info.size.height, width, height)
                        } else {
                            Pair(width, height)
                        }
                    decoder.setTargetSize(newSize.first, newSize.second)
                }
            } catch (err: Exception) {
                throw FailedToDecodeImageFileException("Failed to decode image file: $srcFile: ${err.message}")
            }
        try {
            return ByteArrayOutputStream().use {
                val format = if (type == "png") Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
                check(bitmap.compress(format, quality, it)) { "Failed to encode image" }
                it.toByteArray()
            }
        } finally {
            bitmap.recycle()
        }
    }

    private fun sizeToFit(
        width: Int,
        height: Int,
        maxWidth: Int,
        maxHeight: Int,
    ): Pair<Int, Int> {
        val widthRatio = if (maxWidth == -1) Double.POSITIVE_INFINITY else maxWidth.toDouble() / width
        val heightRatio = if (maxHeight == -1) Double.POSITIVE_INFINITY else maxHeight.toDouble() / height
        val ratio = minOf(1.0, widthRatio, heightRatio)
        return Pair(maxOf(1, (width * ratio).toInt()), maxOf(1, (height * ratio).toInt()))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

class FailedToDecodeImageFileException(
    message: String?,
) : Exception(message)
