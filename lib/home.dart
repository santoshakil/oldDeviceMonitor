import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helpers/db_helper.dart';
import 'db_helpers/db_helper_fid.dart';
import 'db_helpers/db_helper_fid_l.dart';
import 'db_helpers/db_helper_location.dart';
import 'http_client.dart';
import 'package:workmanager/workmanager.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

///import 'package:shared_preferences/shared_preferences.dart';

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    //WidgetsFlutterBinding.ensureInitialized();
    await _HomeState().managerBg();
    print('Background Services are Working!');
    return Future.value(true);
  });
}

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ],
);

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GoogleSignInAccount account;
  ga.DriveApi api;
  GlobalKey<ScaffoldState> _scaffold = GlobalKey();
  GoogleMapController controller;
  Location location = new Location();
  Set<Marker> marker = {};
  final dbLocation = DatabaseHelperLocation.instance;
  final dbFidL = DatabaseHelperFidL.instance;
  final dbFid = DatabaseHelperFid.instance;
  final dbHelper = DatabaseHelper.instance;

  Future<LatLng> getLatLong() async {
    var pos = await location.getLocation();
    var lat = pos.latitude;
    var long = pos.longitude;
    marker.add(
      new Marker(
        markerId: MarkerId("Other Device Location"),
        position: LatLng(lat, long),
        infoWindow: InfoWindow(title: "Other Device Location", onTap: () {}),
      ),
    );
    return LatLng(lat, long);
  }

  // void _onMapCreated(GoogleMapController controller) {
  //   _controller.complete(controller);
  // }

  @override
  void initState() {
    login();
    //WidgetsFlutterBinding.ensureInitialized();
    // Workmanager.initialize(callbackDispatcher, isInDebugMode: true);
    // Workmanager.registerPeriodicTask("1", "simplePeriodicTask",
    //     existingWorkPolicy: ExistingWorkPolicy.replace,
    //     frequency: Duration(minutes: 15),
    //     initialDelay:
    //         Duration(seconds: 5), //duration before showing the notification
    //     constraints: Constraints(
    //       networkType: NetworkType.connected,
    //     ));
    super.initState();
    //manager();
  }

  Future<void> manager() async {
    if (account == null) {
      await login();
      await managerLocal();
      managerDrive();
      // await managerC();
      // managerL();
    } else {
      await managerLocal();
      managerDrive();
      // await managerC();
      // managerL();
    }
  }

  Future<void> managerBg() async {
    await managerLocal();
    managerDrive();
    // await managerC();
    // managerL();
  }

  Widget _test() {
    return IconButton(
      icon: Icon(Icons.adb),
      onPressed: () {
        managerDrive();
      },
    );
  }

  Widget _loginIcon() {
    if (account != null) {
      return IconButton(
        icon: Icon(Icons.check_circle_outline),
        onPressed: () {
          manager();
        },
      );
    } else {
      return IconButton(
        icon: Icon(Icons.account_circle),
        onPressed: () {
          login();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 5,
            backgroundColor: Colors.black,
            actions: <Widget>[
              _test(),
              _loginIcon(),
            ],
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.call)),
                //Tab(icon: Icon(Icons.message)),
                Tab(icon: Icon(Icons.location_on)),
              ],
            ),
            title: Text('Device Monitor'),
          ),
          body: TabBarView(
            children: [
              FutureBuilder(
                  future: CallLog.get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      List<CallLogEntry> entries = snapshot.data.toList();
                      return Scrollbar(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            var entry = entries[index];
                            var mono = TextStyle(fontFamily: 'monospace');

                            return Column(
                              children: <Widget>[
                                Divider(),
                                Text('NUMBER   : ${entry.number}', style: mono),
                                Text('NAME     : ${entry.name}', style: mono),
                                Text('TYPE     : ${entry.callType}',
                                    style: mono),
                                Text(
                                    'DATE     : ${DateTime.fromMillisecondsSinceEpoch(entry.timestamp)}',
                                    style: mono),
                                Text('DURATION :  ${entry.duration}',
                                    style: mono),
                              ],
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                            );
                          },
                          itemCount: entries.length,
                        ),
                      );
                    }
                  }),
              FutureBuilder(
                future: getLatLong(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    return GoogleMap(
                      onMapCreated: (controlle) {
                        setState(() {
                          controller = controlle;
                        });
                      },
                      initialCameraPosition: CameraPosition(
                        target: snapshot.data,
                        zoom: 16.0,
                      ),
                      //myLocationEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                      markers: marker,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> callLogDbUpdate() async {
    Iterable<CallLogEntry> cLog = await CallLog.get();
    cLog.toList().asMap().forEach((cLogIndex, log) async {
      // row to update
      Map<String, dynamic> row = {
        DatabaseHelper.columnId: cLogIndex,
        DatabaseHelper.columnName: '${log.name}',
        DatabaseHelper.columnNumber: '${log.number}',
        DatabaseHelper.columnType: '${log.callType}',
        DatabaseHelper.columnDate:
            '${DateTime.fromMillisecondsSinceEpoch(log.timestamp)}',
        DatabaseHelper.columnDuration: '${log.duration}'
      };
      await dbHelper.update(row);
      print('CallLog updated $cLogIndex:: $row');
    });
  }

  Future<void> callLogDbInsert() async {
    Iterable<CallLogEntry> cLog = await CallLog.get();
    int rowCount = await DatabaseHelper.instance.queryRowCount();
    int clLength = cLog.length;
    int rows = clLength - rowCount;
    for (int i = 0; i < rows; i++) {
      // row to insert
      Map<String, dynamic> row = {
        //DatabaseHelper.columnId: cLogIndex,
        DatabaseHelper.columnName: 'Blank',
        DatabaseHelper.columnNumber: 0,
        DatabaseHelper.columnType: 'Blank',
        DatabaseHelper.columnDate: 0,
        DatabaseHelper.columnDuration: 0
      };
      await dbHelper.insert(row, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Row(s) inserted $i:: $row');
    }
  }

  Future<void> callLogDbManager() async {
    Iterable<CallLogEntry> cLog = await CallLog.get();
    int rowCount = await DatabaseHelper.instance.queryRowCount();
    int clLength = cLog.length;
    if (rowCount >= clLength) {
      callLogDbUpdate();
    } else {
      await callLogDbInsert();
      callLogDbUpdate();
    }
  }

  Future<void> uploadFile() async {
    final filename = 'MyDatabase.db';
    final gFile = ga.File();
    gFile.name = filename;
    final dir = await getExternalStorageDirectory();
    final localFile = File('${dir.path}/$filename');
    final createdFile = await api.files.create(gFile,
        uploadMedia: ga.Media(localFile.openRead(), localFile.lengthSync()));
    Map<String, dynamic> row = {
      DatabaseHelperFid.columnFname: filename,
      DatabaseHelperFid.columnFid: '${createdFile.id}'
    };
    await dbFid.insert(row);

    print('New file created ${createdFile.id}');
    //setState(() {});
  }

  Future<void> updateFile(String fID) async {
    final filename = 'MyDatabase.db';
    final gFile = ga.File();
    gFile.name = filename;

    final dir = await getExternalStorageDirectory();
    final localFile = File('${dir.path}/$filename');
    final createdFile = await api.files.update(gFile, fID,
        uploadMedia: ga.Media(localFile.openRead(), localFile.lengthSync()));

    print('File updated ${createdFile.id}');
    //setState(() {});
  }

  Future<void> listDrive() async {
    var client = GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
    var drive = ga.DriveApi(client);
    var response = await drive.files.list();
    print('files:');
    response.files.forEach((f) async {
      if (f.name == 'MyDatabase.db') {
        String fID = f.id;
        print('File ${f.name} is found');
        updateFile(fID);
        Map<String, dynamic> row = {
          DatabaseHelperFid.columnId: 1,
          DatabaseHelperFid.columnFname: 'MyDatabase.db',
          DatabaseHelperFid.columnFid: '$fID'
        };
        await dbFid.update(row);
      } else {
        print('file not Found.');
      }
    });
  }

  Future<void> driveFileManage() async {
    int d = await DatabaseHelperFid.instance.queryRowCount();
    if (d != 0) {
      listDrive();
    } else {
      uploadFile();
    }
  }

  // Future<void> managerC() async {
  //   await callLogDbManager();
  //   driveFileManage();
  // }

  ///
  Future<void> locationDbUpdate() async {
    try {
      await location.getLocation().then((onValue) async {
        var latitude = onValue.latitude.toString();
        var longitude = onValue.longitude.toString();
        Map<String, dynamic> row = {
          DatabaseHelperLocation.columnId: 1,
          DatabaseHelperLocation.columnLatitude: latitude,
          DatabaseHelperLocation.columnLongitude: longitude
        };
        await dbLocation.update(row);
        print('Updated Location $row');
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> locationDbInsert() async {
    try {
      await location.getLocation().then((onValue) async {
        var latitude = onValue.latitude.toString();
        var longitude = onValue.longitude.toString();
        Map<String, dynamic> row = {
          DatabaseHelperLocation.columnLatitude: latitude,
          DatabaseHelperLocation.columnLongitude: longitude
        };
        await dbLocation.insert(row);
        print('Inserted Location $row');
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> locationDbManager() async {
    int rowCount = await DatabaseHelperLocation.instance.queryRowCount();
    if (rowCount != 0) {
      locationDbUpdate();
    } else {
      await locationDbInsert();
      locationDbUpdate();
    }
  }

  Future<void> uploadFileL() async {
    final filename = 'Location.db';
    final gFile = ga.File();
    gFile.name = filename;
    final dir = await getExternalStorageDirectory();
    final localFile = File('${dir.path}/$filename');
    final createdFile = await api.files.create(gFile,
        uploadMedia: ga.Media(localFile.openRead(), localFile.lengthSync()));
    Map<String, dynamic> row = {
      DatabaseHelperFidL.columnFname: filename,
      DatabaseHelperFidL.columnFid: '${createdFile.id}'
    };
    await dbFidL.insert(row);

    print('New file created ${createdFile.id}');
    setState(() {});
  }

  Future<void> updateFileL(String fID) async {
    final filename = 'Location.db';
    final gFile = ga.File();
    gFile.name = filename;

    final dir = await getExternalStorageDirectory();
    final localFile = File('${dir.path}/$filename');
    final createdFile = await api.files.update(gFile, fID,
        uploadMedia: ga.Media(localFile.openRead(), localFile.lengthSync()));

    print('File updated ${createdFile.id}');
    setState(() {});
  }

  Future<void> listDriveL() async {
    var client = GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
    var drive = ga.DriveApi(client);
    var response = await drive.files.list();
    print('files:');
    response.files.forEach((f) async {
      if (f.name == 'Location.db') {
        String fID = f.id;
        print('File ${f.name} is found');
        updateFileL(fID);
        Map<String, dynamic> row = {
          DatabaseHelperFidL.columnId: 1,
          DatabaseHelperFidL.columnFname: 'Location.db',
          DatabaseHelperFidL.columnFid: '$fID'
        };
        await dbFidL.update(row);
      } else {
        print('file not Found.');
      }
    });
  }

  Future<void> driveFileManageL() async {
    int d = await DatabaseHelperFidL.instance.queryRowCount();
    if (d != 0) {
      listDriveL();
    } else {
      uploadFileL();
    }
  }

  // Future<void> managerL() async {
  //   await locationDbManager();
  //   driveFileManageL();
  // }

  ///
  Future<void> managerLocal() async {
    await callLogDbManager();
    locationDbManager();
  }

  Future<void> managerDrive() async {
    await driveFileManage();
    driveFileManageL();
  }

  ///

  items() async {
    Iterable<CallLogEntry> cLog = await CallLog.get();
    int c = cLog.length;
    int d = await DatabaseHelper.instance.queryRowCount();
    print('Call Log Length: $c');
    print('Database Length: $d');
  }

  Future<void> login() async {
    try {
      account = await _googleSignIn.signIn();
      final client =
          GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
      api = ga.DriveApi(client);
    } catch (error) {
      print('DriveScreen.login.ERROR... $error');
      _scaffold.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          'Error : $error',
          style: TextStyle(color: Colors.white),
        ),
      ));
    }
    setState(() {});
  }

  // void logout() {
  //   _googleSignIn.signOut();
  //   setState(() {
  //     account = null;
  //   });
  // }
}
