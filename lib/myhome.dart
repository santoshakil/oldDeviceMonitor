import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'dart:async';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'db_helpers/db_helper_location.dart';
import 'db_helpers/db_helper_myhome.dart';
import 'http_client.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ],
);

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  GoogleSignInAccount account;
  ga.DriveApi api;
  GlobalKey<ScaffoldState> _scaffold = GlobalKey();
  final db = DatabaseHelperMyHome.instance;
  final dbl = DatabaseHelperLocation.instance;
  GoogleMapController controller;
  Set<Marker> marker = {};

  Future<LatLng> getLatLong() async {
    var lat = await dbl.queryLatitude();
    var long = await dbl.queryLongitude();
    int i = await dbl.queryRowCount();
    if (i != 0) {
      marker.add(new Marker(
          markerId: MarkerId("Other Device Location"),
          position: LatLng(double.parse(lat), double.parse(long)),
          infoWindow:
              InfoWindow(title: "Other Device Location", onTap: () {})));
      return LatLng(double.parse(lat), double.parse(long));
    } else {
      return LatLng(0, 0);
    }
  }

  @override
  void initState() {
    //manager();
    super.initState();
  }

  Future<void> manager() async {
    await login();
    await getCallLogDB();
    getLocationDB();
    items();
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
                  future: db.queryAllRows(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      var entries = snapshot.data.toList();
                      return Scrollbar(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            var entry = entries[index];
                            var mono = TextStyle(fontFamily: 'monospace');

                            return Column(
                              children: <Widget>[
                                Divider(),
                                Text('NUMBER   : ${entry.toString()}',
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

  Future<void> getCallLogDB() async {
    var client = GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
    var drive = ga.DriveApi(client);
    var response = await drive.files.list();
    final directory = await getExternalStorageDirectory();
    final fname = 'MyDatabase.db';
    print('files:');
    response.files.forEach((f) async {
      if (f.name == 'MyDatabase.db') {
        String fID = f.id;
        ga.Media file = await api.files
            .get(fID, downloadOptions: ga.DownloadOptions.FullMedia);

        print(file.stream);
        print(directory.path);

        final saveFile = io.File('${directory.path}/$fname');
        List<int> dataStore = [];

        file.stream.listen((data) {
          print("DataReceived: ${data.length}");
          dataStore.insertAll(dataStore.length, data);
        }, onDone: () {
          print("Task Done");
          saveFile.writeAsBytes(dataStore);
          print("File saved at ${saveFile.path}");
        }, onError: (error) {
          print("Some Error");
        });
      } else {}
    });
  }

  Future<void> getLocationDB() async {
    var client = GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
    var drive = ga.DriveApi(client);
    var response = await drive.files.list();
    final directory = await getExternalStorageDirectory();
    final fname = 'Location.db';
    print('files:');
    response.files.forEach((f) async {
      if (f.name == 'Location.db') {
        String fID = f.id;
        ga.Media file = await api.files
            .get(fID, downloadOptions: ga.DownloadOptions.FullMedia);

        print(file.stream);
        print(directory.path);

        final saveFile = io.File('${directory.path}/$fname');
        List<int> dataStore = [];

        file.stream.listen((data) {
          print("DataReceived: ${data.length}");
          dataStore.insertAll(dataStore.length, data);
        }, onDone: () {
          print("Task Done");
          saveFile.writeAsBytes(dataStore);
          print("File saved at ${saveFile.path}");
        }, onError: (error) {
          print("Some Error");
        });
      } else {}
    });
  }

  items() async {
    int count = await db.queryRowCount();
    print(count);
    return count;
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
}
