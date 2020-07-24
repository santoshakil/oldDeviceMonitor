import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelperLocation {
  static final _databaseName = "Location.db";
  static final _databaseVersion = 1;
  static final table = 'my_table';
  static final columnId = 'id';
  static final columnLatitude = 'Latitude';
  static final columnLongitude = 'Longitude';

  DatabaseHelperLocation._privateConstructor();
  static final DatabaseHelperLocation instance =
      DatabaseHelperLocation._privateConstructor();
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getExternalStorageDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnLatitude INTEGER,
            $columnLongitude INTEGER
          )
          ''');
  }

  Future<int> insert(Map<String, dynamic> row,
      {ConflictAlgorithm conflictAlgorithm}) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  queryLatitude() async {
    Database db = await DatabaseHelperLocation.instance.database;

    List<String> columnsToSelect = [DatabaseHelperLocation.columnLatitude];
    String whereString = '${DatabaseHelperLocation.columnId} = ?';
    int rowId = 1;
    List<dynamic> whereArguments = [rowId];
    List<Map> result = await db.query(DatabaseHelperLocation.table,
        columns: columnsToSelect,
        where: whereString,
        whereArgs: whereArguments);

    if (result.length != 0) {
      var latitude = result.first.values.single.toString();
      print(latitude);
      return latitude;
    } else {
      print('QueryFID is null');
      return null;
    }
  }

  queryLongitude() async {
    Database db = await DatabaseHelperLocation.instance.database;

    List<String> columnsToSelect = [DatabaseHelperLocation.columnLongitude];
    String whereString = '${DatabaseHelperLocation.columnId} = ?';
    int rowId = 1;
    List<dynamic> whereArguments = [rowId];
    List<Map> result = await db.query(DatabaseHelperLocation.table,
        columns: columnsToSelect,
        where: whereString,
        whereArgs: whereArguments);

    if (result.length != 0) {
      var longitude = result.first.values.single.toString();
      print(longitude);
      return longitude;
    } else {
      print('QueryFID is null');
      return null;
    }
  }
}
