package com.example.hanzicard_app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.iflytek.cloud.* // Requires iflytek Msc.jar
import com.iflytek.cloud.util.ResourceUtil

import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hanzicard/tts"
    private var mTts: SpeechSynthesizer? = null
    
    // Replace with your actual AppID if needed, or pass it from Flutter
    private val APP_ID = "03935d0a" // PLEASE REPLACE THIS WITH YOUR REAL APPID 

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    try {
                        val commonPath = call.argument<String>("commonPath")
                        val voicePath = call.argument<String>("voicePath")
                        initTts(commonPath, voicePath)
                        result.success(true)
                    } catch (e: Throwable) {
                        Log.e("IflytekTTS", "Init fatal error", e)
                        result.error("INIT_ERROR", e.message, null)
                    }
                }
                "speak" -> {
                    val text = call.argument<String>("text")
                    if (text != null) {
                        speak(text)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Text is null", null)
                    }
                }
                "stop" -> {
                    stopSpeaking()
                    result.success(true)
                }
                "setSpeed" -> {
                    val speed = call.argument<Int>("speed")
                    if (speed != null) {
                        setSpeed(speed)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Speed is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initTts(commonPath: String?, voicePath: String?) {
        // Initialize SpeechUtility
        // Note: This requires the correct native libraries (.so) to be present
        val utility = SpeechUtility.createUtility(this, SpeechConstant.APPID + "=$APP_ID")
        Toast.makeText(this, "TTS Init AppID: " + SpeechConstant.APPID + "=$APP_ID", Toast.LENGTH_LONG).show()

        if (utility == null) {
             Log.e("IflytekTTS", "SpeechUtility init failed: returned null")
             Toast.makeText(this, "TTS Init Failed: utility is null", Toast.LENGTH_LONG).show()
             return
        }

        // Create Synthesizer
        mTts = SpeechSynthesizer.createSynthesizer(this) { code ->
            Log.d("IflytekTTS", "InitListener init() code = $code")
            if (code != ErrorCode.SUCCESS) {
                Toast.makeText(this, "Synthesizer Init Failed: $code", Toast.LENGTH_LONG).show()
            }
        }
        
        if (mTts == null) {
            Log.e("IflytekTTS", "Failed to create SpeechSynthesizer")
            Toast.makeText(this, "Synthesizer is null", Toast.LENGTH_LONG).show()
            return
        }

        // Set parameters for Offline TTS
        mTts!!.setParameter(SpeechConstant.PARAMS, null)
        mTts!!.setParameter(SpeechConstant.ENGINE_TYPE, SpeechConstant.TYPE_XTTS)

        if (!commonPath.isNullOrEmpty() && !voicePath.isNullOrEmpty()) {
            // Set resource path: fo|common.jet;fo|voice_name.jet
            // Note: iFlytek offline engine requires 'fo|' prefix for file paths
            val resourcePath = "fo|$commonPath;fo|$voicePath"
            Log.d("IflytekTTS", "Setting resource path: $resourcePath")
            Toast.makeText(this, "Resource Path: $resourcePath", Toast.LENGTH_LONG).show()
            val setRes = mTts!!.setParameter(ResourceUtil.TTS_RES_PATH, resourcePath)
            if (!setRes) {
                Log.e("IflytekTTS", "Failed to set resource path")
                Toast.makeText(this, "Failed to set resource path", Toast.LENGTH_LONG).show()
            }
        } else {
             Toast.makeText(this, "Resource path is null or empty", Toast.LENGTH_LONG).show()
        }
        
        mTts!!.setParameter(SpeechConstant.VOICE_NAME, "xiaoyan") // Or whatever voice resource name
        
        mTts!!.setParameter(SpeechConstant.SPEED, "50")
        mTts!!.setParameter(SpeechConstant.VOLUME, "80")
        mTts!!.setParameter(SpeechConstant.PITCH, "50")
        
        Toast.makeText(this, "TTS Init Success", Toast.LENGTH_SHORT).show()
    }

    private fun speak(text: String) {
        if (mTts == null) {
            Log.e("IflytekTTS", "TTS not initialized")
            Toast.makeText(this, "TTS not initialized", Toast.LENGTH_SHORT).show()
            return
        }
        
        val code = mTts!!.startSpeaking(text, object : SynthesizerListener {
            override fun onSpeakBegin() {}
            override fun onBufferProgress(percent: Int, beginPos: Int, endPos: Int, info: String?) {}
            override fun onSpeakPaused() {}
            override fun onSpeakResumed() {}
            override fun onSpeakProgress(percent: Int, beginPos: Int, endPos: Int) {}
            override fun onCompleted(error: SpeechError?) {
                if (error != null) {
                    val errorDesc = error.getPlainDescription(true)
                    Log.e("IflytekTTS", "Speak error: $errorDesc")
                    runOnUiThread {
                        Toast.makeText(applicationContext, "Speak Error: $errorDesc", Toast.LENGTH_LONG).show()
                    }
                }
            }
            override fun onEvent(eventType: Int, arg1: Int, arg2: Int, obj: Bundle?) {}
        })

        if (code != ErrorCode.SUCCESS) {
            Log.e("IflytekTTS", "startSpeaking failed, code: $code")
            Toast.makeText(this, "Start Error: $code", Toast.LENGTH_LONG).show()
        }
    }

    private fun stopSpeaking() {
        mTts?.stopSpeaking()
    }

    private fun setSpeed(speed: Int) {
        if (mTts != null) {
            Log.d("IflytekTTS", "Setting speed to $speed")
            mTts!!.setParameter(SpeechConstant.SPEED, speed.toString())
        }
    }
    
    override fun onDestroy() {
        mTts?.stopSpeaking()
        mTts?.destroy()
        super.onDestroy()
    }
}
