// needed for Directory()
import 'dart:io';
import 'dart:typed_data';
// needed for join()
import 'package:path/path.dart';
// needed for SQL database operations
import 'package:sqflite/sqflite.dart';
// needed for getApplicationDocumentsDirectory()
import 'package:path_provider/path_provider.dart';

// database table and column names for skills
final String moods = 'moods';
final String moodsFinished = 'moodsFinished';
final String productivity = 'productivity';
final String productivityFinished = 'productivityFinished';
final String columnId = '_id';
final String columnYear = 'year';
final String columnIntensity = 'intensity';
final String columnText = 'text';
final String columnImage = 'image';
final String columnDay = 'day';
final String columnTimestamp = 'timestamp';

//data model class
class PixelData {
  var id;
  var year;
  List<dynamic> image = [0];
  var intensity = 0;
  var text = '';
  var day;
  var timestamp = 0;

  PixelData();

  // convenience constructor to create a skill object
  PixelData.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    year = map[columnYear];
    intensity = map[columnIntensity];
    text = map[columnText];
    image = map[columnImage];
    day = map[columnDay];
    timestamp = map[columnTimestamp];
  }

  // convenience method to create a Map from this Word object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnYear: year,
      columnIntensity: intensity,
      columnText : text,
      columnImage : Uint8List.fromList(image.cast<int>()),
      columnDay : day,
      columnTimestamp : timestamp
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

}

class DatabaseHelper {

  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "MyDatabase.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 1;

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database, can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    //skill table
    await db.execute('''
          CREATE TABLE $moods (
            $columnId INTEGER PRIMARY KEY,
            $columnYear INTEGER NOT NULL,
            $columnIntensity INTEGER NOT NULL,
            $columnText TEXT NOT NULL,
            $columnImage BLOB,
            $columnDay INTEGER NOT NULL,
            $columnTimestamp INTEGER NOT NULL
          )
          ''');
    await db.execute('''
          CREATE TABLE $moodsFinished (
            $columnId INTEGER PRIMARY KEY,
            $columnYear INTEGER NOT NULL,
            $columnIntensity INTEGER NOT NULL,
            $columnText TEXT NOT NULL,
            $columnImage BLOB,
            $columnDay INTEGER NOT NULL,
            $columnTimestamp INTEGER NOT NULL
          )
          ''');
    await db.execute('''
          CREATE TABLE $productivity (
            $columnId INTEGER PRIMARY KEY,
            $columnYear INTEGER NOT NULL,
            $columnIntensity INTEGER NOT NULL,
            $columnText TEXT NOT NULL,
            $columnImage BLOB,
            $columnDay INTEGER NOT NULL,
            $columnTimestamp INTEGER NOT NULL
          )
          ''');
    await db.execute('''
          CREATE TABLE $productivityFinished (
            $columnId INTEGER PRIMARY KEY,
            $columnYear INTEGER NOT NULL,
            $columnIntensity INTEGER NOT NULL,
            $columnText TEXT NOT NULL,
            $columnImage BLOB,
            $columnDay INTEGER NOT NULL,
            $columnTimestamp INTEGER NOT NULL
          )
          ''');
    print("tables created");

    print("shop initialized");
  }

  // Database helper methods:
  Future<int> insert(String table, dataObject) async {
    Database db = await database;
    int id = await db.insert(table, dataObject.toMap()); //ohh tableWords is the name of the table FGDKSDHHAFJD
    return id;
  }

  //populates a table with 365 rows with default values (none)
  Future populate(String table, year) async {
    Database db = await database;
    Batch batch = db.batch();
    PixelData pixelData = new PixelData();
    pixelData.year = year;
    for(var i = 1; i <= 365 ; i ++){
      pixelData.day = i;
      batch.insert(table, pixelData.toMap());
      print('inserted day ${pixelData.day}  of ${pixelData.year} with value ${pixelData.intensity} with id  ${pixelData.id} at table $table');
    }
    await batch.commit(noResult: true);
  }

  //copies table to another table
  Future copyTable(copiedTable, copierTable) async {
    Database db = await database;
    List<Map> maps = await db.query(copiedTable);
    maps.forEach((map) {
      var id = db.insert(copierTable, map);
      print('inserted map of id $id to $copierTable');
    });
  }

  //resets table values to default
  Future resetValues(String table, int year, timestamp) async {
    Database db = await database;
    PixelData pixelData = new PixelData();
    pixelData.year = year;
    pixelData.timestamp = timestamp;
    //TODO:: fix this           \/\/\/
    for(var i = 1; i <= 365 ; i++){
      pixelData.day = i ;
      await db.update(table, pixelData.toMap(),
          where: '$columnId = ?', whereArgs: [i]);
      //print('reset id $i with day ${pixelData.day} with intensity ${pixelData.intensity}');
    }
    List<Map> maps = await db.query(table);
    print('maps queried');
    if (maps.length > 0) {
      print('maps length > 0, length: ${maps.length}');
      List<PixelData> pixels = [];
      //print('TEST FROM RESETVALUES first day is ${maps[0]['intensity']}');
      maps.forEach((map) => pixels.add(PixelData.fromMap(map)));
      print('$pixels pixel list');
      print('map data added!');
      return pixels;
    }
    return null;

  }

  Future<PixelData> queryPixel(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(moods,
        columns: [columnId, columnYear, columnIntensity, columnText, columnImage, columnDay],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return PixelData.fromMap(maps.first);
    }
    return null;
  }

  //returns all items
  Future<List<PixelData>> queryAll(String table) async {
    print('queryAll called');
    Database db = await database;
    print('database initializes');
    List<Map> maps = await db.query(table);
    print('maps queried');
    if (maps.length > 0) {
      print('maps length > 0, length: ${maps.length}');
      List<PixelData> pixels = [];

      maps.forEach((map) => pixels.add(PixelData.fromMap(map)));
      print('$pixels pixel list');
      print('map data added!');
      return pixels;
    }
    return null;
  }
  //with condition
  Future<List> queryWithCondition(String table, String category, String whereArgs,String category2, String whereArgs2, inputObject) async {
    Database db = await database;
    List <Map> maps = await db.rawQuery('SELECT * FROM $table WHERE $category = $whereArgs AND $category2 = $whereArgs2');
    //List<Map> maps = await db.query(table, where: '$category = ?', whereArgs: [whereArgs]);
    if (maps.length > 0) {
      List items = [];
      maps.forEach((map) => items.add(inputObject.fromMap(map)));
      return items;
    }
    return null;
  }
  Future<List> rawQuery(String queryString, inputObject) async {
    Database db = await database;
    List <Map> maps = await db.rawQuery('$queryString');
    //List<Map> maps = await db.query(table, where: '$category = ?', whereArgs: [whereArgs]);
    if (maps.length > 0) {
      List items = [];
      maps.forEach((map) => items.add(inputObject.fromMap(map)));
      return items;
    }
    return null;
  }

  /*Future<int> deleteWord(int id) async {
    Database db = await database;
    return await db.delete(moods, where: '$columnId = ?', whereArgs: [id]);
  }*/


  Future<int> update(String table, int id, dataObject) async {
    Database db = await database;
    return await db.update(table, dataObject.toMap(),
        where: '$columnId = ?', whereArgs: [id]);
  }

  /*
  Future<int> updateWithMap(String table, int id, Map map) async {
    Database db = await database;
    return await db.update(table, map,
        where: '$columnId = ?', whereArgs: [id]);
  }
  */

}
