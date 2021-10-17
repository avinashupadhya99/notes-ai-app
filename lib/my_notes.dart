import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mock_data/mock_data.dart';

import 'package:flutter/material.dart';

class MyNotes extends StatefulWidget {
  const MyNotes({Key? key}) : super(key: key);

  @override
  _MyNotesState createState() => _MyNotesState();
}

class _MyNotesState extends State<MyNotes> {
  List notes = List.empty();

  void getList() async {
    final res = await http
        .get(Uri.parse("https://wenote-api.neeltron.repl.co/display"));

    if (res.statusCode == 200) {
      var v = json.decode(res.body);
      print(v);
      setState(() {
        notes = v;
      });
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
      const Text('My Notes', style: TextStyle(fontSize: 50)),
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
          DateTime noteDate = mockDate(DateTime.parse('2021-10-16 00:18:04'));
          return ListTile(
            leading: const Icon(Icons.album),
            title: Text('${notes[index]['note']}'),
            subtitle: Text(noteDate.toLocal().toString()),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ))
    ]);
  }
}
