// import 'dart:io' as io;
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart';
// import 'package:http/io_client.dart';

// class GoogleHttpClient extends IOClient {
//   Map<String, String> _headers;

//   GoogleHttpClient(this._headers) : super();

//   @override
//   Future<IOStreamedResponse> send(BaseRequest request) =>
//       super.send(request..headers.addAll(_headers));

//   @override
//   Future<Response> head(Object url, {Map<String, String> headers}) =>
//       super.head(url, headers: headers..addAll(_headers));
// }

// GoogleSignIn _googleSignIn = GoogleSignIn(
//   scopes: [
//     'email',
//     'https://www.googleapis.com/auth/drive.file',
//   ],
// );

// class DriveScreen extends StatefulWidget {
//   @override
//   DriveScreenState createState() {
//     return new DriveScreenState();
//   }
// }

// class DriveScreenState extends State<DriveScreen> {
//   GoogleSignInAccount account;

//   DriveApi api;

//   GlobalKey<ScaffoldState> _scaffold = GlobalKey();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffold,
//       appBar: AppBar(
//         title: Text('Flutter to drive'),
//         actions: account == null
//             ? []
//             : <Widget>[
//                 IconButton(icon: Icon(Icons.exit_to_app), onPressed: logout)
//               ],
//       ),
//       body: Center(
//         child: account == null
//             ? Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: RaisedButton(child: Text('Login'), onPressed: login),
//               )
//             : Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: <Widget>[
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: CircleAvatar(
//                           radius: 20,
//                           backgroundImage:
//                               NetworkImage(account.photoUrl, scale: 0.3),
//                           backgroundColor: Colors.yellow,
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(account.displayName),
//                       )
//                     ],
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: RaisedButton(
//                         child: Text('save random file'), onPressed: toDrive),
//                   ),
//                   Expanded(
//                     child: FutureBuilder(
//                         initialData: null,
//                         future: api.files.list(),
//                         builder: (context, AsyncSnapshot snapshot) {
//                           if (snapshot.hasData) {
//                             return ListView(
//                               children: (snapshot.data as FileList)
//                                   .files
//                                   .map((f) => ListTile(
//                                         dense: true,
//                                         title: Text(f.name),
//                                         leading: Icon(Icons.insert_drive_file),
//                                       ))
//                                   .toList(),
//                             );
//                           }
//                           if (snapshot.hasError)
//                             return Center(
//                               child: Text('Error ${snapshot.error}'),
//                             );
//                           return SizedBox();
//                         }),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Future<void> login() async {
//     try {
//       account = await _googleSignIn.signIn();
//       final client =
//           GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
//       api = DriveApi(client);
//     } catch (error) {
//       print('DriveScreen.login.ERROR... $error');
//       _scaffold.currentState.showSnackBar(SnackBar(
//         backgroundColor: Colors.red.shade700,
//         content: Text(
//           'Error : $error',
//           style: TextStyle(color: Colors.white),
//         ),
//       ));
//     }
//     setState(() {});
//   }

//   void toDrive() async {
//     final filename = 'file-${DateTime.now().millisecondsSinceEpoch}.txt';

//     final gFile = File();
//     gFile.name = filename;

//     final dir = await getApplicationDocumentsDirectory();
//     final localFile = io.File('${dir.path}/$filename');
//     await localFile.create();
//     await localFile.writeAsString('$filename');

//     final createdFile = await api.files.create(gFile,
//         uploadMedia: Media(localFile.openRead(), localFile.lengthSync()));

//     _scaffold.currentState.showSnackBar(SnackBar(
//       content: Text('File saved => id : ${createdFile.id}'),
//     ));

//     // rebuild to refresh file list
//     setState(() {});
//   }

//   void logout() {
//     _googleSignIn.signOut();
//     setState(() {
//       account = null;
//     });
//   }
// }
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
// import 'dart:io';
// import 'package:googleapis/abusiveexperiencereport/v1.dart' as commons;
// import 'package:googleapis/drive/v3.dart' as ga;
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as p;

// import 'package:google_sign_in/google_sign_in.dart'
//     show GoogleSignIn, GoogleSignInAccount;

// import 'package:http/io_client.dart';
// import 'package:http/http.dart';

// const _scopes = [ga.DriveApi.DriveFileScope];

// GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

// class GoogleDrive {
//   final String defaultFolderName = "Daily Dairy Entries";

//   Future<http.Client> getHttpClient() async {
//     GoogleSignInAccount _account = _googleSignIn.currentUser;

//     if (_account == null) {
//       _account = await _googleSignIn.signInSilently();
//     }

//     if (_account == null) {
//       _account = await _googleSignIn.signIn();
//     }

//     final authHeaders = await _googleSignIn.currentUser.authHeaders;

//     return GoogleHttpClient(authHeaders);
//   }

//   Future<void> authenticate() async {
//     await getHttpClient();
//   }

//   Future<bool> hasCredentialsStored() async {
//     return await _googleSignIn.isSignedIn();
//   }

//   void clearAuthentication() {
//     _googleSignIn.signOut();
//   }

//   // Returns ID of folder that was created
//   Future<String> createFolder() async {
//     var client = await getHttpClient();
//     var drive = ga.DriveApi(client);
//     ga.File fileMetadata = ga.File();
//     fileMetadata.name = defaultFolderName;
//     fileMetadata.mimeType = "application/vnd.google-apps.folder";

//     ga.File response = await drive.files.create(fileMetadata, $fields: 'id');
//     print("Created folder: ${response.id}");

//     return response.id;
//   }

//   // Returns true if the specified folder id exists in Drive
//   Future<bool> folderExists(String folderId) async {
//     var client = await getHttpClient();
//     var drive = ga.DriveApi(client);

//     try {
//       ga.FileList folders = await drive.files.list(
//           q: "mimeType='application/vnd.google-apps.folder' and trashed=false and name='$defaultFolderName'",
//           $fields: "nextPageToken, files(id, name)");

//       bool folderFound = false;

//       List<ga.File> files = folders.files;
//       for (int i = 0; i < files.length; i++) {
//         if (files[i].id == folderId) {
//           folderFound = true;
//           break;
//         }
//       }

//       return folderFound;
//     } on commons.ApiRequestError catch (e) {
//       print(e.message);
//       return false;
//     }
//   }

//   //Upload File
//   Future<String> upload(File file, List<String> parents) async {
//     var client = await getHttpClient();
//     var drive = ga.DriveApi(client);
//     print("Uploading file");
//     ga.File driveFile = ga.File();
//     driveFile.name = p.basename(file.absolute.path);
//     driveFile.parents = parents;

//     try {
//       ga.File response = await drive.files.create(driveFile,
//           uploadMedia: ga.Media(file.openRead(), file.lengthSync()));

//       return response.id;
//     } on commons.ApiRequestError catch (e) {
//       print("Failed to upload file: ${file.path}");
//       print(e.toString());
//       print(e.message);
//       return null;
//     }
//   }

//   Future<bool> update(File file, String fileId) async {
//     var client = await getHttpClient();
//     var drive = ga.DriveApi(client);

//     print("Updating file");
//     ga.File driveFile = ga.File();
//     driveFile.name = p.basename(file.absolute.path);

//     try {
//       ga.File response = await drive.files.update(driveFile, fileId,
//           uploadMedia: ga.Media(file.openRead(), file.lengthSync()));
//       print("Result ${response.toJson()}");
//       return true;
//     } on commons.ApiRequestError catch (e) {
//       print("Failed to update file: ${file.path}");
//       print(e.toString());
//       print(e.message);
//       return false;
//     }
//   }

//   // Future<String> driveCreateFolder() async {
//   //   final db = DatabaseHelperFid.instance;
//   //   if (await db.queryfid() == null) {
//   //     var client =
//   //         GoogleHttpClient(await _googleSignIn.currentUser.authHeaders);
//   //     var drive = ga.DriveApi(client);
//   //     ga.File fileMetadata = ga.File();
//   //     fileMetadata.name = "dmdb";
//   //     fileMetadata.mimeType = "application/vnd.google-apps.folder";
//   //     ga.File response = await drive.files.create(fileMetadata, $fields: 'id');
//   //     print("Created folder: ${response.id}");
//   //     Map<String, dynamic> row = {
//   //       DatabaseHelperFid.columnFname: 'fname',
//   //       DatabaseHelperFid.columnFid: '${response.id}'
//   //     };
//   //     await db.insert(row);
//   //     print('inserted row: $row');
//   //     return response.id;
//   //   } else {
//   //     print('Folder Exist');
//   //     return null;
//   //   }
//   // }

//   void list() async {
//     var client = await getHttpClient();
//     var drive = ga.DriveApi(client);
//     var response = await drive.files.list();
//     print('files:');
//     response.files.forEach((f) {
//       print(f.name);
//     });
//   }
// }

// class GoogleHttpClient extends IOClient {
//   Map<String, String> _headers;

//   GoogleHttpClient(this._headers) : super();

//   @override
//   Future<IOStreamedResponse> send(BaseRequest request) =>
//       super.send(request..headers.addAll(_headers));

//   @override
//   Future<Response> head(Object url, {Map<String, String> headers}) =>
//       super.head(url, headers: headers..addAll(_headers));
// }
