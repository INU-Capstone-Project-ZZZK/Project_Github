import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ble/providers/sensor_data_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SensorDataProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Pico BLE Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: "ble test"),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isScanning = false;
  List scanResults = [];
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  late var device;
  late var write_characteristic;

  TextEditingController inputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 권한 및 초기 설정 세팅
    flutterBlueSettings();

    // // 앱 시작 스캔
    // flutterBlueInit();
  }

  void flutterBlueSettings() async {
    // 디바이스의 블루투스 지원 여부 판단.
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    // 블루투스 활성화 권한 창
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  void flutterBlueInit() async {
    // 스캔 결과 listen
    print("스캔 시작");
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          print(
              '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
          print("디바이스 : ");
          print(r.device);
          print("광고데이터 : ");
          print(r.advertisementData);
          device = r.device;
          connect_device(device);
        }
      },
      onError: (e) => print(e),
    );

    // 스캔 종료 시 위 listen 종료
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // 블루투스 활성화 및 권한 부여 테스트
    // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    // 스캔 시작 및 스캔 끝날때까지 기다리기
    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 7),
        withServices: [Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")]);
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  void connect_device(device) async {
    // listen for disconnection
    var connectSubscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        print("연결 끊김");
      }
    });

    // cleanup: cancel subscription when disconnected
    device.cancelWhenDisconnected(connectSubscription,
        delayed: true, next: false);

    // 해당 디바이스와 연결
    await device.connect().then((result) => print("연결 성공"));

    // 서비스 찾기
    List<BluetoothService> services = await device.discoverServices();
    print("찾은 서비스");
    print(services);
    print("=======================");
    for (var service in services) {
      // 캐릭터리스틱 읽기
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        print("캐릭터리스틱 : ");
        print(c);
        print("=======================");
        if (c.properties.read) {
          List<int> value = await c.read();
        } else {
          // 쓰기
          write_characteristic = c;
        }

        final valueSubscription = c.onValueReceived.listen((value) {
          print("값 도착 $value");
          Provider.of<SensorDataProvider>(context, listen: true)
              .convertAscii(value);
        });

        // 연결 끊겼을때 subscribe 해제
        device.cancelWhenDisconnected(valueSubscription);

        // subscribe 설정 - Notify
        await c.setNotifyValue(true);
      }
    }
  }

  Future onStopScan() async {
    print("연결 정지");

    // Disconnect from device
    FlutterBluePlus.stopScan();
    await device.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Provider.of<SensorDataProvider>(context, listen: true)
                      .display_data,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                ElevatedButton(
                    onPressed: onStopScan, child: const Text("stop scan")),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                TextField(
                  controller: inputController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your data..',
                    labelStyle: TextStyle(color: Colors.redAccent),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(width: 1, color: Colors.redAccent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(width: 1, color: Colors.redAccent),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                ElevatedButton(
                    onPressed: () {
                      setState(() async {
                        print("작성한 값 : ${inputController.text}");
                        int parsedInt = int.parse(inputController.text);
                        // 숫자 int값만 전송가능.
                        await write_characteristic.write([parsedInt]);
                      });
                    },
                    child: const Text("send"))
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: flutterBlueInit,
        tooltip: 'Scanning',
        child: const Icon(Icons.add),
      ),
    );
  }
}
