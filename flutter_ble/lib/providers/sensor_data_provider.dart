import 'package:flutter/material.dart';

class SensorDataProvider extends ChangeNotifier {
  String display_data = "None";

  void convertAscii(asciiSignals) {
    display_data = "";

    for (int asciiValue in asciiSignals) {
      display_data += String.fromCharCode(asciiValue);
    }

    print('변환된 시그널: $display_data');
    notifyListeners(); // 상태 변경 알림
  }
}
