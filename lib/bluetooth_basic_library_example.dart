/*
    Created by Shawon Lodh on 22 February 2022
*/

import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_enable/bluetooth_enable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';

class BluetoothBasicLibraryExample extends StatefulWidget {
  @override
  _BluetoothBasicLibraryExampleState createState() => _BluetoothBasicLibraryExampleState();
}

class _BluetoothBasicLibraryExampleState extends State<BluetoothBasicLibraryExample> {
  BluetoothManager bluetoothManager = BluetoothManager.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();
    bluetoothStatus();
    // WidgetsBinding.instance!.addPostFrameCallback((_) => initBluetooth());
  }

  Future<void> bluetoothStatus() async {
    print(await bluetoothManager.isConnected);

  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothManager.startScan(timeout: Duration(seconds: 4));

    bool isConnected = await bluetoothManager.isConnected;

    bluetoothManager.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothManager.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothManager.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  void _onConnect() async {
    if (_device != null && _device!.address != null) {
      await bluetoothManager.connect(_device!);
    } else {
      setState(() {
        tips = 'please select device';
      });
      print('please select device');
    }
  }

  void _onDisconnect() async {
    await bluetoothManager.disconnect();
  }

  void _sendData() async {
    List<int> bytes = latin1.encode('Hello world!\n\n\n').toList();

    // Set codetable west. Add import 'dart:typed_data';
    // List<int> bytes = Uint8List.fromList(List.from('\x1Bt'.codeUnits)..add(6));
    // Text with special characters
    bytes += latin1.encode('blåbærgrød\n\n\n');

    await bluetoothManager.writeData(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Bluetooth Basic Example"),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            bluetoothManager.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(tips),
                  ),
                ],
              ),
              Divider(),
              StreamBuilder<List<BluetoothDevice>>(
                stream: bluetoothManager.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      !.map((d) => ListTile(
                    title: Text(d.name ?? ''),
                    subtitle: Text(d.address! + '\n${d.type}'),
                    onTap: () async {
                      setState(() {
                        _device = d;
                      });
                    },
                    trailing:
                    _device != null && _device!.address == d.address
                        ? const Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                        : null,
                  ))
                      .toList(),
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlinedButton(
                          child: const Text('connect'),
                          onPressed: _connected ? null : _onConnect,
                        ),
                        SizedBox(width: 10.0),
                        OutlinedButton(
                          child: const Text('disconnect'),
                          onPressed: _connected ? _onDisconnect : null,
                        ),
                      ],
                    ),
                    OutlinedButton(
                      child: const Text('Send test data'),
                      onPressed: _connected ? _sendData : null,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bluetoothManager.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: () => bluetoothManager.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: (){
                  bluetoothManager.startScan(timeout: const Duration(seconds: 4));
                });
          }
        },
      ),
    );
  }
}