import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class MyNotes extends StatefulWidget {
  const MyNotes({Key? key}) : super(key: key);

  @override
  _MyNotesState createState() => _MyNotesState();
}

class _MyNotesState extends State<MyNotes> {
  List notes = List.empty();

  void getList() async {
    final res = await http.get(Uri.parse(
        "https://WildAware-Server-and-Hardware.neeltron.repl.co/output"));

    if (res.statusCode == 200) {
      var v = json.decode(res.body);
      print(v);
      notes = v;
    }
  }

  @override
  Widget build(BuildContext context) {
    getList();
    if (notes.isEmpty) {
      return Container(
        height: 50,
        color: Colors.lightBlue,
        child: const Center(child: Text('No notes saved!')),
      );
    }
    return Column(children: <Widget>[
      TextField(
        onChanged: (value) => {},
        decoration: const InputDecoration(
            labelText: 'Search', suffixIcon: Icon(Icons.search)),
      ),
      Expanded(
          child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: notes.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.network(
                notes[index]['url'],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              ListTile(
                leading: const Icon(Icons.album),
                title: Text('${notes[index]['aname']}'),
                subtitle: Text('${notes[index]['desc']}'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Found at ${notes[index]['loc']}'),
                  TextButton(
                    child: const Text('Report'),
                    onPressed: () {/* ... */},
                  ),
                ],
              ),
            ],
          ));
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ))
    ]);
  }
}
