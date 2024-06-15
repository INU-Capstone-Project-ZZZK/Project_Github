import 'package:flutter/material.dart';

class SensorDataProvider extends ChangeNotifier {
  String data = "None";
  String display_data = "None";
  double progress = 0;
  List<double> input = [];
  List<double> angle_input = [];

  void convertAscii(asciiSignals) async {
    angle_input = [];
    data = "";
    print(asciiSignals);
    for (int asciiValue in asciiSignals) {
      data += String.fromCharCode(asciiValue);
    }
    input =
        data.split(',').map((signal) => double.parse(signal.trim())).toList();
    print(input);
    await to_in();

    notifyListeners(); // 상태 변경 알림
  }

  Future<void> to_in() async {
    for (int i = 0; i < 3; i++) {
      angle_input.add(input[i]);
    }
  }
}

int argmax(List<double> data) {
  double maxValue = double.negativeInfinity;
  int maxIndex = -1;

  // 이중 List를 순회하며 최대값과 그 인덱스를 찾습니다.
  for (int i = 0; i < data.length; i++) {
    if (data[i] > maxValue) {
      maxValue = data[i];
      maxIndex = i;
    }
  }

  return maxIndex;
}
