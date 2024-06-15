import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_ble/provider/sensor_data_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SensorDataProvider(),
      child: MyApp(),
    ),
  );
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
        title: 'sleep class Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: "sleep classify"),
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
  int check = 0;

  final _modelFile = 'assets/sleep_position_model.tflite';

  late Interpreter _interpreter;

  List<String> _output = ['wake', 'rem', 'sleep'];
  List<String> _output2 = ['supine', 'left', 'right', 'prone'];
  String sleep_class = 'start please';
  String sleep_position = 'start please';
  String connected = 'false';

  List<int> vib_level = [
    0, // 직접 테스트했을 때 15000부터 직접적인 떨림이 느껴졋음
    1,
    2,
    3,
    4,
    5 //65535은 너무 과도하다 사실 50000대부터 깨는 위험이 충분히 있지만 현재는 이렇게 설정
  ];

  Timer? _timer;
  Map<String, String> postSleepPosition = {};

  @override
  void initState() {
    super.initState();

    backgroudSetting();

    // 권한 및 초기 설정 세팅
    // 모델 불러오기
    flutterBlueSettings();
    _loadModel();
    // // 앱 시작 스캔
    flutterBlueInit();

    // **********************************
    // DB 저장
    // _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    //   // print("?��?�� ?��면자?�� : $sleep_class");
    //   postSleepPosition["sleep_position"] = sleep_position;
    //   await PostServices.insertHeartrate(postSleepPosition);
    // });
  }

  void backgroudSetting() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "flutter_background example app",
      notificationText:
          "Background notification for keeping the example app running in the background",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(
          name: 'background_icon',
          defType: 'drawable'), // Default is ic_launcher from folder mipmap
    );
    bool success =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    print(success);
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

  void _loadModel() async {
    // 모델 생성
    _interpreter = await Interpreter.fromAsset(_modelFile);
    print('Interpreters loaded successfully');
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
          print("device : ");
          print(r.device);
          print("advertising data : ");
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

  double time_cache = 0;
  bool init = false;
  Future<void> run() async {
    setState(() {
      if (Provider.of<SensorDataProvider>(context, listen: false).input[3] <
          5) {
        sleep_class = _output[0];
      } else {
        if (init == false) {
          init = true;
          // wake -> sleep
          now_sleep_level = 2;
          sleep_class = _output[now_sleep_level];
        }

        if (time_cache == 0) {
          time_cache =
              Provider.of<SensorDataProvider>(context, listen: false).input[3];
        } else {
          // wake
          if (now_sleep_level == 0) {
            // 10분
            if (Provider.of<SensorDataProvider>(context, listen: false)
                        .input[3] -
                    time_cache >=
                5) {
              now_sleep_level = 2;
              sleep_class = _output[now_sleep_level];
              time_cache =
                  Provider.of<SensorDataProvider>(context, listen: false)
                      .input[3];
            }
          }
          // rem
          else if (now_sleep_level == 1) {
            // 30분
            if (Provider.of<SensorDataProvider>(context, listen: false)
                        .input[3] -
                    time_cache >=
                5) {
              now_sleep_level = 2;
              sleep_class = _output[now_sleep_level];
              time_cache =
                  Provider.of<SensorDataProvider>(context, listen: false)
                      .input[3];
            }
          }
        }
      }
    });
  }

  // 진동 컨트롤 용 변수 선언
  String former_sleep_pos = '';
  int now_vib_level = 0;
  int now_sleep_level = 0;
  int cnt = 0;

  void vib() async {
    // 오른쪽이거나 뒤집힌 자세일 때
    // 진동을 가한다.
    if (sleep_class == _output[2]) {
      if (sleep_position == _output2[2] || sleep_position == _output2[3]) {
        // 이전 수면자세와 같을 시 즉 진동에도 변화가 없을 시
        // 피코에서 5초 동안 진동을 주고 다시 똑같은 자세인지 판단  똑같다면 진동 레벨 증가
        if (former_sleep_pos == _output2[2] ||
            former_sleep_pos == _output2[3]) {
          cnt++;
          if (cnt == 1 && now_vib_level < vib_level.length) {
            now_vib_level += 1;
            cnt = 0;
          }
        }
        // 이전 수면자세가 올바른 자세였다면
        // 초기 세팅으로 진동 전달 시작
        else {
          now_vib_level = 1;
          cnt = 0;
        }
        await write_characteristic.write([vib_level[now_vib_level]]);
      }
      // 올바른 자세라면 진동을 주지 않는다.
      else {
        now_vib_level = 0;
        cnt = 0;
        // 진동을 주지 않음에도 보내는 이유는 계속 진동 모터가 작동중이기 때문이다.
        if (former_sleep_pos == _output2[2] ||
            former_sleep_pos == _output2[3]) {
          await write_characteristic.write([0]);
        }
      }
    } else {
      if (now_vib_level >= 1) {
        now_vib_level = 0;
        cnt = 0;
        await write_characteristic.write([0]);
      }
    }
  }

  late dynamic connectSubscription;

  void connect_device(device) async {
    // 해당 디바이스와 연결
    await device.connect().then((result) => print("connection sucess"));
    setState(() {
      connected = 'true';
    });
    // 서비스 찾기
    List<BluetoothService> services = await device.discoverServices();
    print("find service");
    print(services);
    print("=======================");
    for (var service in services) {
      // 캐릭터리스틱 읽기
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        print("characteristic : ");
        print(c);
        print("=======================");
        if (c.properties.read) {
          List<int> value = await c.read();
        } else {
          // 쓰기
          write_characteristic = c;
        }

        final valueSubscription = c.onValueReceived.listen((value) async {
          print("value arrived $value");
          Provider.of<SensorDataProvider>(context, listen: false)
              .convertAscii(value);

          // sleep class renew
          await run();
          var output = List<double>.filled(4, 0.0).reshape([1, 4]);
          _interpreter.run([
            Provider.of<SensorDataProvider>(context, listen: false).angle_input
          ], output);

          setState(() {
            sleep_position = _output2[argmax(output[0])];
            if (former_sleep_pos != sleep_position) {
              if (now_sleep_level != 0) {
                now_sleep_level = now_sleep_level - 1;
                sleep_class = _output[now_sleep_level];
                time_cache = 0;
              }
            }
            vib();
            former_sleep_pos = sleep_position;
          });
        });

        // listen for disconnection
        connectSubscription = device.connectionState
            .listen((BluetoothConnectionState state) async {
          if (state == BluetoothConnectionState.disconnected) {
            print("connection stopped");
            setState(() {
              connected = 'false';
            });
          }
        });
        // cleanup: cancel subscription when disconnected
        device.cancelWhenDisconnected(connectSubscription,
            delayed: true, next: false);

        // 연결 끊겼을때 subscribe 해제
        device.cancelWhenDisconnected(valueSubscription);

        // subscribe 설정 - Notify
        await c.setNotifyValue(true);
      }
    }
  }

  Future restart() async {
    print("restart");

    setState(() {
      init = false;
      sleep_class = _output[0];
      time_cache = 0;
    });
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
                ElevatedButton(
                    onPressed: restart, child: const Text("restart")),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                Text(
                  'sleep class is $sleep_class',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                Text(
                  'sleep position is $sleep_position',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
                Text(
                  'connected: $connected',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 10.0,
                  width: 30.0,
                ),
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


