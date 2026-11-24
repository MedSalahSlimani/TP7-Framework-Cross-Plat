import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'api.dart';
import 'auth_widgets.dart';
import 'models.dart';
import 'session.dart';
import 'totals_screen.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({Key? key}) : super(key: key);
  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  List<Departement> depts = [];
  List<Classe> classes = [];
  List<Etudiant> students = [];
  List<Matiere> matieres = [];
  List<Absence> absences = [];

  int? deptId, classId, studentId;
  bool loading = true;
  bool error = false;

  final nomCtrl = TextEditingController();
  final prenomCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInit();
  }

  @override
  void dispose() {
    nomCtrl.dispose();
    prenomCtrl.dispose();
    super.dispose();
  }

  Etudiant? get currentStudent {
    for (final s in students) {
      if (s.id == studentId) return s;
    }
    return null;
  }

  String get deptName =>
      depts.where((d) => d.codDept == deptId).map((d) => d.nomDept).firstOrNull ??
          '';

  String get classeName =>
      classes.where((c) => c.codClass == classId).map((c) => c.nomClass).firstOrNull ??
          '';

  Future<List> _getList(String path) async {
    final res = await http.get(Uri.parse("$baseUrl$path"));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as List;
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---------- chargement en cascade : dept -> classes -> étudiants -> absences

  Future<void> loadInit() async {
    try {
      depts = (await _getList("/api/departements"))
          .map((e) => Departement.fromMap(e))
          .toList();
      matieres = (await _getList("/api/matieres"))
          .map((e) => Matiere.fromMap(e))
          .toList();
      if (depts.isNotEmpty) {
        deptId = depts.first.codDept;
        await loadClasses();
      }
    } catch (_) {
      error = true;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> loadClasses() async {
    classes = (await _getList("/api/classes/departement/$deptId"))
        .map((e) => Classe.fromMap(e))
        .toList();
    classId = classes.isEmpty ? null : classes.first.codClass;
    await loadStudents();
  }

  Future<void> loadStudents() async {
    if (classId == null) {
      students = [];
    } else {
      students = (await _getList("/api/etudiants/classe/$classId"))
          .map((e) => Etudiant.fromMap(e))
          .toList();
    }
    studentId = students.isEmpty ? null : students.first.id;
    await loadAbsences();
  }

  Future<void> loadAbsences() async {
    final s = currentStudent;
    nomCtrl.text = s?.nom ?? '';
    prenomCtrl.text = s?.prenom ?? '';
    if (s == null) {
      absences = [];
    } else {
      absences = (await _getList("/api/absences/etudiant/${s.id}"))
          .map((e) => Absence.fromMap(e))
          .toList();
    }
    if (mounted) setState(() {});
  }

  // exécute un chargement en gérant les erreurs réseau
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) _snack("Cannot reach the server");
    }
  }

  // ---------- ajout / modification / suppression d'une absence

  Future<void> absenceDialog({Absence? a}) async {
    final s = currentStudent;
    if (s == null) {
      _snack("Select a student first");
      return;
    }
    if (matieres.isEmpty) {
      _snack("No subjects available");
      return;
    }
    String date = a?.dateA ?? DateTime.now().toIso8601String().substring(0, 10);
    String codMat = a?.codMat ?? matieres.first.codMat;
    final nha = TextEditingController(text: a == null ? '' : fmtNum(a.nha));

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(a == null ? "New absence" : "Edit absence"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(fmtDate(date)),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(date),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    setLocal(() => date = d.toIso8601String().substring(0, 10));
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: codMat,
                items: matieres
                    .map((m) =>
                    DropdownMenuItem(value: m.codMat, child: Text(m.codMat)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setLocal(() => codMat = v);
                },
              ),
              TextField(
                controller: nha,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "NHA (hours)"),
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

    final hours = double.tryParse(nha.text.trim().replaceAll(',', '.'));
    if (hours == null) {
      _snack("Invalid number of hours");
      return;
    }

    final body = json.encode({
      'dateA': date,
      'nha': hours,
      'matiere': {'codMat': codMat},
      'etudiant': {'id': s.id},
    });
    final headers = {'Content-Type': 'application/json'};
    try {
      final res = a == null
          ? await http.post(Uri.parse("$baseUrl/api/absences"),
          headers: headers, body: body)
          : await http.put(Uri.parse("$baseUrl/api/absences/${a.id}"),
          headers: headers, body: body);
      if (res.statusCode != 200) {
        _snack("Save failed (${res.statusCode})");
        return;
      }
      await loadAbsences();
    } catch (_) {
      _snack("Cannot reach the server");
    }
  }

  Future<void> deleteAbsence(Absence a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete absence?"),
        content: Text("${fmtDate(a.dateA)} - ${a.codMat} - ${fmtNum(a.nha)} h"),
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
    try {
      await http.delete(Uri.parse("$baseUrl/api/absences/${a.id}"));
      await loadAbsences();
    } catch (_) {
      _snack("Cannot reach the server");
    }
  }

  // ---------- interface

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              isDense: true,
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, TextEditingController c) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: c,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF4F3FF),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  );

  Widget _table() {
    if (absences.isEmpty) {
      return const Center(child: Text("No absences"));
    }
    final admin = Session.isAdmin;
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEDEBFF)),
          columns: [
            const DataColumn(label: Text("DateA")),
            const DataColumn(label: Text("CodMat")),
            const DataColumn(label: Text("NHA"), numeric: true),
            if (admin) const DataColumn(label: Text("")),
          ],
          rows: absences
              .map((a) => DataRow(cells: [
            DataCell(Text(fmtDate(a.dateA))),
            DataCell(Text(a.codMat)),
            DataCell(Text(fmtNum(a.nha))),
            if (admin)
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: kPrimary),
                    onPressed: () => absenceDialog(a: a)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteAbsence(a)),
              ])),
          ]))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = currentStudent;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Absences"),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Total per subject",
            icon: const Icon(Icons.bar_chart),
            onPressed: s == null
                ? null
                : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TotalsScreen(
                    etudiant: s, classe: classeName, dept: deptName),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Session.isAdmin
          ? FloatingActionButton(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          onPressed: () => absenceDialog(),
          child: const Icon(Icons.add))
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? const Center(child: Text("Cannot reach the server"))
          : depts.isEmpty
          ? const Center(child: Text("No departments"))
          : Column(
        children: [
          const SizedBox(height: 12),
          // 3 listes : département, classe, étudiant
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              _dropdown<int>(
                label: "Dept.",
                value: deptId,
                items: depts
                    .map((d) => DropdownMenuItem(
                    value: d.codDept,
                    child: Text(d.nomDept)))
                    .toList(),
                onChanged: (v) => _run(() async {
                  deptId = v;
                  await loadClasses();
                }),
              ),
              _dropdown<int>(
                label: "Classe",
                value: classId,
                items: classes
                    .map((c) => DropdownMenuItem(
                    value: c.codClass,
                    child: Text(c.nomClass)))
                    .toList(),
                onChanged: (v) => _run(() async {
                  classId = v;
                  await loadStudents();
                }),
              ),
              _dropdown<int>(
                label: "Etudiant",
                value: studentId,
                items: students
                    .map((e) => DropdownMenuItem(
                    value: e.id!, child: Text(e.code)))
                    .toList(),
                onChanged: (v) => _run(() async {
                  studentId = v;
                  await loadAbsences();
                }),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // nom et prénom de l'étudiant sélectionné
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              _readOnlyField("Nom", nomCtrl),
              _readOnlyField("Prénom", prenomCtrl),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(),
          // tableau des absences
          Expanded(child: _table()),
        ],
      ),
    );
  }
}