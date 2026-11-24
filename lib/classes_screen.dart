import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'api.dart';
import 'auth_widgets.dart';
import 'models.dart';
import 'session.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({Key? key}) : super(key: key);
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  late Future<List<Classe>> future;

  @override
  void initState() {
    super.initState();
    future = fetchClasses();
  }

  Future<List<Classe>> fetchClasses() async {
    final res = await http.get(Uri.parse("$baseUrl/api/classes"));
    if (res.statusCode != 200) throw Exception('Loading error');
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Classe.fromMap(e)).toList();
  }

  void reload() => setState(() => future = fetchClasses());

  // add (c == null) or edit (c != null)
  Future<void> classeDialog({Classe? c}) async {
    List<Departement> depts = [];
    try {
      final r = await http.get(Uri.parse("$baseUrl/api/departements"));
      depts = (jsonDecode(utf8.decode(r.bodyBytes)) as List)
          .map((e) => Departement.fromMap(e))
          .toList();
    } catch (_) {}

    final nom = TextEditingController(text: c?.nomClass ?? '');
    int? codDept = c?.codDept;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(c == null ? "New group" : "Edit group"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nom,
                decoration:
                const InputDecoration(labelText: "Name (ex: DSI33)")),
            const SizedBox(height: 12),
            DropdownButton<int>(
              isExpanded: true,
              value: codDept,
              hint: const Text("Department"),
              items: depts
                  .map((d) => DropdownMenuItem(
                  value: d.codDept, child: Text(d.nomDept)))
                  .toList(),
              onChanged: (v) => setLocal(() => codDept = v),
            ),
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
      ),
    );
    if (ok != true || nom.text.trim().isEmpty) return;

    final body = json.encode({
      'nomClass': nom.text.trim(),
      'departement': codDept == null ? null : {'codDept': codDept},
    });
    final headers = {'Content-Type': 'application/json'};
    if (c == null) {
      await http.post(Uri.parse("$baseUrl/api/classes"),
          headers: headers, body: body);
    } else {
      await http.put(Uri.parse("$baseUrl/api/classes/${c.codClass}"),
          headers: headers, body: body);
    }
    reload();
  }

  Future<void> deleteClasse(Classe c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete group?"),
        content: Text("${c.nomClass} and its students will be deleted."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await http.delete(Uri.parse("$baseUrl/api/classes/${c.codClass}"));
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Manage groups"),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white),
      floatingActionButton: Session.isAdmin
          ? FloatingActionButton(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          onPressed: () => classeDialog(),
          child: const Icon(Icons.add))
          : null,
      body: FutureBuilder<List<Classe>>(
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
            return const Center(child: Text("No groups yet."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: kPrimary,
                    child: Icon(Icons.groups, color: Colors.white)),
                title: Text(list[i].nomClass),
                subtitle: Text(
                    "${list[i].nbreEtud} students${list[i].nomDept != null ? ' • ${list[i].nomDept}' : ''}"),
                onTap: Session.isAdmin ? () => classeDialog(c: list[i]) : null,
                trailing: Session.isAdmin
                    ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteClasse(list[i]))
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}