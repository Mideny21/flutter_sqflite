import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqlite/personDb.dart';

import 'main.dart';
import 'person_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PersonDB _crudStorage;

  @override
  void initState() {
    _crudStorage = PersonDB(dbName: 'db.sqlite');
    _crudStorage.open();
    super.initState();
  }

  @override
  void dispose() {
    _crudStorage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("CRUD APP SQFLITE"),
      ),
      body: StreamBuilder(
        stream: _crudStorage.all(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
            case ConnectionState.waiting:
              if (snapshot.data == null) {
                return const CircularProgressIndicator();
              }
              final people = snapshot.data as List<Person>;
              if (kDebugMode) {
                print(people);
              }
              return Column(
                children: [
                  ComposeWidget(onCompose: (firstName, lastName) async {
                    await _crudStorage.create(firstName, lastName);
                  }),
                  Expanded(
                    child: ListView.builder(
                        itemCount: people.length,
                        itemBuilder: (context, index) {
                          final person = people[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan)),
                              child: ListTile(
                                onTap: () async {
                                  final editedPerson =
                                      await showUpdateDialog(context, person);
                                  if (editedPerson != null) {
                                    await _crudStorage.update(editedPerson);
                                  }
                                },
                                title: Text(person.fullName),
                                subtitle: Text('ID: ${person.id}'),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final shouldDelete =
                                        await showDeleteDialog(context);
                                    if (kDebugMode) {
                                      print(shouldDelete);
                                    }
                                    if (shouldDelete) {
                                      await _crudStorage.delete(person);
                                    }
                                  },
                                  child: const Icon(
                                      Icons.disabled_by_default_rounded,
                                      color: Colors.red),
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ],
              );
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
