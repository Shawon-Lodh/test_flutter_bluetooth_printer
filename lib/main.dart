import 'package:image/image.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:oktoast/oktoast.dart';
import 'package:test_flutter_bluetooth_printer/bluetooth_basic_library_example.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Bluetooth demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // home: MyHomePage(title: 'Bluetooth demo'),\
        home: BluetoothBasicLibraryExample(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];

  @override
  void initState() {
    super.initState();

    printerManager.scanResults.listen((devices) async {
      // print('UI: Devices found ${devices.length}');
      setState(() {
        _devices = devices;
        for(int i = 0;i<_devices.length;i++){
          print("Name : ${_devices[i].name}, Address : ${_devices[i].address}, Type : ${_devices[i].type}");
        }
      });
    });
  }

  void _startScanDevices() {
    setState(() {
      _devices = [];
    });
    printerManager.startScan(const Duration(seconds: 4));
  }

  void _stopScanDevices() {
    printerManager.stopScan();
  }

  Future<List<int>> demoReceipt(
      PaperSize paper, CapabilityProfile profile) async {
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];

    bytes += ticket.text('GLOBAL LEAF TOBACCO COMPANY LTD',
        styles: const PosStyles(align: PosAlign.center));

    bytes += ticket.text('Crop Year 2021',
        styles: const PosStyles(align: PosAlign.center));

    bytes += ticket.text('Tobacco Transport Permit',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += ticket.qrcode("testtesttesttesttesttesttesttest",size: QRSize.Size8,align: PosAlign.center);

    bytes += ticket.text('Name : Ramiz Uddin',
        styles: const PosStyles(align: PosAlign.center));
    bytes += ticket.text('Father Name : Sukkor Molla',
        styles: const PosStyles(align: PosAlign.center));
    bytes += ticket.text('Reg No : 1234567890',
        styles: const PosStyles(align: PosAlign.center));
    bytes += ticket.text('Bale : 5',
        styles: const PosStyles(align: PosAlign.center));
    bytes += ticket.text('Ext Center : Rongpur',
        styles: const PosStyles(align: PosAlign.center));
    bytes += ticket.text('Tp Issue Date : ${DateTime.now()}',
        styles: const PosStyles(align: PosAlign.center));
    bytes += ticket.hr();

    final ByteData data = await rootBundle.load('assets/images/default.png');
    final Uint8List buffer= data.buffer.asUint8List();
    final  image = decodeImage(buffer);

    bytes += ticket.image(image!);

    bytes += ticket.feed(2);
    bytes += ticket.text('Thank you!',
        styles: PosStyles(align: PosAlign.center, bold: true));

    final now = DateTime.now();
    final formatter = DateFormat('MM/dd/yyyy H:m');
    final String timestamp = formatter.format(now);
    bytes += ticket.text(timestamp,
        styles: const PosStyles(align: PosAlign.center), linesAfter: 2);

    ticket.feed(2);
    ticket.cut();
    return bytes;
  }

  void _testPrint(PrinterBluetooth printer) async {
    printerManager.selectPrinter(printer);

    // TODO Don't forget to choose printer's paper
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();

    // TEST PRINT
    // final PosPrintResult res =
    // await printerManager.printTicket(await testTicket(paper));

    // DEMO RECEIPT
    final PosPrintResult res =
    await printerManager.printTicket((await demoReceipt(paper, profile)));

    showToast(res.msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () => _testPrint(_devices[index]),
              child: Column(
                children: <Widget>[
                  Container(
                    height: 80,
                    padding: EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.print),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(_devices[index].name ?? ''),
                              Text(_devices[index].address!),
                              Text(_devices[index].type!.toString()),
                              Text(
                                'Click to print a test receipt',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                ],
              ),
            );
          }),
      floatingActionButton: StreamBuilder<bool>(
        stream: printerManager.isScanningStream,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: _stopScanDevices,
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: _startScanDevices,
            );
          }
        },
      ),
    );
  }

}
