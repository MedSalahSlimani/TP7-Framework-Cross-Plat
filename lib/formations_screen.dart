import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'session.dart';
import 'api.dart';
import 'auth_widgets.dart';
import 'models.dart';

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({Key? key}) : super(key: key);
  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  late Future<List<Formation>> future;

  @override
  void initState() {
    super.initState();
    future = fetch();
  }

  Future<List<Formation>> fetch() async {
    final res = await http.get(Uri.parse("$baseUrl/api/formations"));
    if (res.statusCode != 200) throw Exception('Error');
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Formation.fromMap(e)).toList();
  }

  void reload() => setState(() => future = fetch());

  // add (f == null) or edit (f != null)
  Future<void> formationDialog({Formation? f}) async {
    final nom = TextEditingController(text: f?.nom ?? '');
    final duree = TextEditingController(text: f == null ? '' : '${f.duree}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(f == null ? "New training" : "Edit training"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nom,
              decoration: const InputDecoration(labelText: "Name")),
          TextField(
              controller: duree,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Duration (hours)")),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save")),
        ],
      ),
    );
    if (ok != true || nom.text.trim().isEmpty) return;
    final body = json.encode(
        {'nom': nom.text.trim(), 'duree': int.tryParse(duree.text) ?? 0});
    final headers = {'Content-Type': 'application/json'};
    if (f == null) {
      await http.post(Uri.parse("$baseUrl/api/formations"),
          headers: headers, body: body);
    } else {
      await http.put(Uri.parse("$baseUrl/api/formations/${f.id}"),
          headers: headers, body: body);
    }
    reload();
  }

  Future<void> remove(int id) async {
    await http.delete(Uri.parse("$baseUrl/api/formations/$id"));
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Manage trainings"),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white),
      floatingActionButton: Session.isAdmin
          ? FloatingActionButton(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          onPressed: () => formationDialog(),
          child: const Icon(Icons.add))
          : null,
      body: FutureBuilder<List<Formation>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text("Cannot reach the server"));
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text("No trainings yet. Tap + to add."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: kPrimary,
                    child: Icon(Icons.menu_book, color: Colors.white)),
                title: Text(list[i].nom),
                subtitle: Text("${list[i].duree} h"),
                onTap: Session.isAdmin
                    ? () => formationDialog(f: list[i])
                    : null,
                trailing: Session.isAdmin
                    ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => remove(list[i].id))
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}