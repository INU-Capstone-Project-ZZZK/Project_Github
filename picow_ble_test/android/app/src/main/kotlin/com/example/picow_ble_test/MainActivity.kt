package com.example.picow_ble_test
// Flutter와 통신하기 위한 플랫폼 채널을 설정합니다.
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import org.python.core.PyString
import org.python.util.PythonInterpreter


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.picow_ble_test/python"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Flutter에서 Kotlin 코드를 호출하기 위한 MethodChannel을 설정합니다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // 호출된 메서드가 "runPythonFile"일 때 실행됩니다.
            if(call.method == "runPythonFile") {
                val filePath = call.argument<String>("filePath")
                
                // 파이썬 파일을 실행하고 결과를 반환합니다.
                val resultValue = runPythonFile(filePath)
                result.success(resultValue)
            } else {
                result.notImplemented()
            }
            
        }
    }


    // 파이썬 파일을 실행하는 함수입니다.
    private fun runPythonFile(filePath: String?): String {
        try {
            // 파이썬 인터프리터를 생성합니다.
            val pythonInterpreter = PythonInterpreter()
            // 파이썬 파일을 실행합니다.
            pythonInterpreter.execfile(filePath)
            // 실행 결과를 가져옵니다.
            // val outputStream = pythonInterpreter.getOut()
            // val result = if (outputStream is PyString) outputStream.toString() else "No output"
            return "파일 실행 완료"
        } catch (e: Exception) {
            // 에러가 발생한 경우 에러 메시지를 반환합니다.
            return "Error occurred: ${e.message}"
        }
    }
}
