import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'person_model.dart';

class PersonDB {
  final String dbName;
  PersonDB({required this.dbName});
  Database? _db;
  List<Person> _persons = [];
  final _streamController = StreamController<List<Person>>.broadcast();

  Future<List<Person>> _fetchPeople() async {
    final db = _db;
    if (db == null) {
      return [];
    }

    try {
      final read = await db.query('PEOPLE',
          distinct: true,
          columns: [
            'ID',
            'FIRST_NAME',
            'LAST_NAME',
          ],
          orderBy: 'ID');

      final people = read.map((row) => Person.fromRow(row)).toList();
      return people;
    } catch (e) {
      return [];
    }
  }

  Future<bool> create(String firstName, String lastName) async {
    final db = _db;
    if (db == null) {
      return false;
    }

    try {
      final id = await db.insert('PEOPLE', {
        'FIRST_NAME': firstName,
        'LAST_NAME': lastName,
      });
      final person = Person(id: id, firstName: firstName, lastName: lastName);
      _persons.add(person);
      _streamController.add(_persons);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> update(Person person) async {
    final db = _db;
    if (db == null) {
      return false;
    }

    try {
      final updateCount = await db.update(
        'PEOPLE',
        {
          'FIRST_NAME': person.firstName,
          'LAST_NAME': person.lastName,
        },
        where: 'ID = ?',
        whereArgs: [person.id],
      );
      if (updateCount == 1) {
        _persons.removeWhere((element) => element.id == person.id);
        _persons.add(person);
        _streamController.add(_persons);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> delete(Person person) async {
    final db = _db;
    if (db == null) {
      return false;
    }

    try {
      final deleteCount =
          await db.delete('PEOPLE', where: 'ID = ?', whereArgs: [person.id]);

      if (deleteCount == 1) {
        _persons.remove(person);
        _streamController.add(_persons);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> close() async {
    final db = _db;
    if (db == null) {
      return false;
    }

    await db.close();
    return true;
  }

  Future<bool> open() async {
    if (_db != null) {
      return true;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$dbName';

    try {
      final db = await openDatabase(path);
      _db = db;

      // Create table
      const create = '''
      CREATE TABLE IF NOT EXISTS PEOPLE(
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      FIRST_NAME STRING NOT  NULL,
      LAST_NAME STRING NOT NULL
      )
        ''';

      await db.execute(create);
      // read all existing Person objects from the db
      _persons = await _fetchPeople();
      _streamController.add(_persons);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error = $e');
      }
      return false;
    }
  }

  Stream<List<Person>> all() =>
      _streamController.stream.map((persons) => persons..sort());
}
