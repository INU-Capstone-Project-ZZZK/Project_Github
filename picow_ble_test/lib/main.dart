import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter AppBar 예제',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('상단바와 가운데 버튼'),
            centerTitle: true, // 제목을 가운데로 정렬
          ),
          body: const MyWidget()),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  static const MethodChannel _channel =
      MethodChannel('com.example.picow_ble_test/python');

  var return_string = '';
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          // 버튼이 눌렸을 때 할 일을 여기에 작성
          print("버튼 눌림");
          final String result = await _channel
              .invokeMethod("runPythonFile", {"filePath": "/assets/test.py"});
          print("파이썬 파일 실행 결과: $result");
        },
        child: const Text('가운데 버튼'),
      ),
    );
  }
}
