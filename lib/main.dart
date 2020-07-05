import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'myhome.dart';

void main() {
  runApp(MaterialApp(
    home: Selector(),
  ));
}

class Selector extends StatefulWidget {
  @override
  _SelectorState createState() => _SelectorState();
}

class _SelectorState extends State<Selector> {
  bool pageReady = false;

  /// This checks the whether page has been selected earlier,
  /// should be placed in an initstate function
  _checkPages() async {
    SharedPreferences local = await SharedPreferences.getInstance();
    if (local.getString('page-selected') != null) {
      if (local.getString('page-selected') == "1") {
        //navigate to MyHome

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHome()),
        );
      } else {
        //Navigate to Home
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
    } else {
      setState(() {
        pageReady = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPages();
  }

  savePage(String type) async {
    if (type == "1") {
      SharedPreferences local = await SharedPreferences.getInstance();
      local.setString('page-selected', type);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyHome()),
      );
    } else {
      SharedPreferences local = await SharedPreferences.getInstance();
      local.setString('page-selected', type);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: pageReady
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    savePage("1");
                  },
                  child: Text('My Device'),
                ),
                SizedBox(height: 30),
                RaisedButton(
                  onPressed: () {
                    savePage("2");
                  },
                  child: Text('Others Device'),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
