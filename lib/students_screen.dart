import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'api.dart';
import 'auth_widgets.dart';
import 'models.dart';
import 'session.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Classe> classes = [];
  List<Formation> formations = [];
  List<Etudiant> students = [];
  Classe? selected;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      final r1 = await http.get(Uri.parse("$baseUrl/api/classes"));
      final r2 = await http.get(Uri.parse("$baseUrl/api/formations"));
      classes = (jsonDecode(utf8.decode(r1.bodyBytes)) as List)
          .map((e) => Classe.fromMap(e))
          .toList();
      formations = (jsonDecode(utf8.decode(r2.bodyBytes)) as List)
          .map((e) => Formation.fromMap(e))
          .toList();
      if (classes.isNotEmpty) {
        selected = classes.first; // first class selected at start
        await loadStudents();
      }
    } catch (_) {
      error = true;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> loadStudents() async {
    if (selected == null) return;
    final res = await http
        .get(Uri.parse("$baseUrl/api/etudiants/classe/${selected!.codClass}"));
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    if (!mounted) return;
    setState(() => students = data.map((e) => Etudiant.fromMap(e)).toList());
  }

  // add (e == null) or edit (e != null)
  Future<void> studentDialog({Etudiant? e}) async {
    if (selected == null) return;
    final nom = TextEditingController(text: e?.nom ?? '');
    final prenom = TextEditingController(text: e?.prenom ?? '');
    final nce = TextEditingController(text: e?.nce ?? '');
    final lieu = TextEditingController(text: e?.lieuNais ?? '');
    String? date = e?.dateNais;
    int? formationId = e?.formationId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(e == null ? "New student" : "Edit student"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: nce,
                  decoration: const InputDecoration(labelText: "NCE (ex: E1)")),
              TextField(
                  controller: nom,
                  decoration: const InputDecoration(labelText: "Last name")),
              TextField(
                  controller: prenom,
                  decoration: const InputDecoration(labelText: "First name")),
              TextField(
                  controller: lieu,
                  decoration:
                  const InputDecoration(labelText: "Place of birth")),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.cake),
                label: Text(date ?? "Date of birth"),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                    date != null ? DateTime.parse(date!) : DateTime(2003),
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) {
                    setLocal(() => date = d.toIso8601String().substring(0, 10));
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                isExpanded: true,
                value: formationId,
                hint: const Text("Training"),
                items: formations
                    .map((f) =>
                    DropdownMenuItem(value: f.id, child: Text(f.nom)))
                    .toList(),
                onChanged: (v) => setLocal(() => formationId = v),
              ),
            ]),
          ),
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
    if (ok != true) return;

    final body = json.encode({
      'nom': nom.text.trim(),
      'prenom': prenom.text.trim(),
      'nce': nce.text.trim().isEmpty ? null : nce.text.trim(),
      'lieuNais': lieu.text.trim(),
      'dateNais': date,
      'classe': {'codClass': selected!.codClass},
      'formation': formationId == null ? null : {'id': formationId},
    });
    final headers = {'Content-Type': 'application/json'};
    if (e == null) {
      await http.post(Uri.parse("$baseUrl/api/etudiants"),
          headers: headers, body: body);
    } else {
      await http.put(Uri.parse("$baseUrl/api/etudiants/${e.id}"),
          headers: headers, body: body);
    }
    await loadStudents();
  }

  Future<void> deleteStudent(int id) async {
    await http.delete(Uri.parse("$baseUrl/api/etudiants/$id"));
    await loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Manage students"),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white),
      floatingActionButton: Session.isAdmin
          ? FloatingActionButton(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          onPressed: () => studentDialog(),
          child: const Icon(Icons.add))
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? const Center(child: Text("Cannot reach the server"))
          : classes.isEmpty
          ? const Center(
          child: Text("Create a group first (Manage groups)."))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Text("Classe : ",
                  style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<Classe>(
                  isExpanded: true,
                  value: selected,
                  hint: const Text("Code Classe"),
                  items: classes
                      .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.nomClass)))
                      .toList(),
                  onChanged: (c) {
                    setState(() => selected = c);
                    loadStudents();
                  },
                ),
              ),
            ]),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text("No students"))
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                final sub = [
                  if (s.formationNom != null)
                    s.formationNom!,
                  if (s.dateNais != null) s.dateNais!,
                ].join(' • ');
                return ListTile(
                  leading: const CircleAvatar(
                      child: Icon(Icons.person)),
                  title: Text("${s.nom} ${s.prenom}"),
                  subtitle: sub.isEmpty ? null : Text(sub),
                  onTap: Session.isAdmin
                      ? () => studentDialog(e: s)
                      : null,
                  trailing: Session.isAdmin
                      ? IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () =>
                          deleteStudent(s.id!))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}