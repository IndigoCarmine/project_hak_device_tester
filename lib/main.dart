import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:project_hak_device_tester/work.dart';
import 'usb_servo.dart';
import 'serialport.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestHome(title: 'Flutter Demo Home Page'),
    );
  }
}

class TestHome extends StatefulWidget {
  const TestHome({super.key, required this.title});

  final String title;
  @override
  State<TestHome> createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  List<Work> works = [];
  late HAKDevice device;
  @override
  void initState() {
    super.initState();
    device = HAKDevice();
    device.connectUSB().then((value) => setState(() {
          device.sendPacket(Packet(ServoCommand.startOrStopMotor.toInt(),
              Uint8List.fromList([0xFF])));
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text(" Usb connected")));
          }
        }));
    works.add(PauseWork());
    works.add(AjustWork(255));
    works.add(MoveWork(255));
    for (int i = 9; i >= 0; i--) {
      works.add(MoveWork(255 ~/ 10 * i));
    }
    works.add(AjustWork(255));
  }

  void sendAngle(double angle) {
    device.sendPacket(Packet(
        ServoCommand.setAngle.toInt(), Uint8List.fromList([angle.toInt()]),
        lowerbyte: 0x02));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          TextButton(
              onPressed: () {
                works.firstOrNull?.isHighlighted = true;
                setState(() {});
              },
              child: const Text("RUN")),
          Expanded(
              child: ListView.builder(
                  itemCount: works.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: WorkWidget(
                          sendAngle: sendAngle,
                          work: works[index],
                          onFinished: () {
                            works[index].isHighlighted = false;
                            if (index + 1 < works.length) {
                              works[index + 1].isHighlighted = true;
                            }
                            setState(() {});
                          }),
                    );
                  }))
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        await device.connectUSB();
        device.sendPacket(Packet(
            ServoCommand.startOrStopMotor.toInt(), Uint8List.fromList([0xFF])));
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text(" Usb connected")));
        }
      }),
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
  String output = "";

  HAKDevice hakdevice = HAKDevice();
  Packet packet = Packet(ServoCommand.setAngle.toInt(), Uint8List(1));
  void _incrementCounter() async {
    if (await hakdevice.connectUSB()) {
      //show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("connected")));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
                onPressed: () async {
                  hakdevice.sendPacket(Packet(
                      ServoCommand.startOrStopMotor.toInt(),
                      Uint8List.fromList([0xFF])));
                  setState(() {});
                },
                child: const Text("Servo Activate")),
            Slider(
              onChanged: (value) {
                packet.data[0] = value.toInt();
                setState(() {});
                hakdevice.sendPacket(packet);
              },
              value: packet.data[0].toDouble(),
              min: 0,
              max: 255,
            ),
            TextField(
              onChanged: (value) {
                int? id = int.tryParse(value);
                if (id == null) {
                  return;
                }
                print(id);
                packet.lowerbyte = id & 0x0F;
              },
              keyboardType: TextInputType.number,
            ),
            TextButton(
                onPressed: () {
                  print("send");
                  print(packet.lowerbyte);
                  print(packet.command);
                  print(packet.data);
                  print(packet.toUint8List());
                  hakdevice.sendPacket(packet);
                },
                child: const Text("send")),
            Expanded(
                child: StreamBuilder(
                    stream: hakdevice.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!.data.toString());
                      } else {
                        return const Text("no data");
                      }
                    }))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
