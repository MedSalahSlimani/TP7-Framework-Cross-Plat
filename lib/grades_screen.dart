import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'api.dart';
import 'auth_widgets.dart';
import 'models.dart';
import 'session.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({Key? key}) : super(key: key);
  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<Departement> depts = [];
  List<Classe> classes = [];
  List<Etudiant> students = [];
  List<Matiere> matieres = [];
  List<GradeRow> rows = [];
  double? moyenne;

  int? deptId, classId, studentId;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    loadInit();
  }

  Etudiant? get currentStudent {
    for (final s in students) {
      if (s.id == studentId) return s;
    }
    return null;
  }

  Future<List> _getList(String path) async {
    final res = await http.get(Uri.parse("$baseUrl$path"));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as List;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---------- chargement en cascade : dept -> classes -> étudiants -> notes

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
    await loadGrades();
  }

  Future<void> loadGrades() async {
    final s = currentStudent;
    if (s == null) {
      rows = [];
      moyenne = null;
    } else {
      final res = await http.get(Uri.parse("$baseUrl/api/notes/etudiant/${s.id}"));
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      rows = (data['notes'] as List).map((e) => GradeRow.fromMap(e)).toList();
      moyenne = (data['moyenne'] as num?)?.toDouble();
    }
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) _snack("Cannot reach the server");
    }
  }

  // ---------- ajout / modification d'une note

  Future<void> gradeDialog({GradeRow? g}) async {
    final s = currentStudent;
    if (s == null || classId == null) {
      _snack("Select a student first");
      return;
    }
    if (matieres.isEmpty) {
      _snack("No subjects available");
      return;
    }
    String codMat = g?.codMat ?? matieres.first.codMat;
    final note = TextEditingController(text: g == null ? '' : fmtNum(g.note));
    final coef = TextEditingController(text: g == null ? '1' : fmtNum(g.coef));

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(g == null ? "New grade" : "Edit grade"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButton<String>(
                isExpanded: true,
                value: codMat,
                items: matieres
                    .map((m) =>
                    DropdownMenuItem(value: m.codMat, child: Text(m.codMat)))
                    .toList(),
                onChanged: g != null
                    ? null // on ne change pas la matière en modification
                    : (v) {
                  if (v != null) setLocal(() => codMat = v);
                },
              ),
              TextField(
                controller: note,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Grade (0 - 20)"),
              ),
              TextField(
                controller: coef,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration:
                const InputDecoration(labelText: "Coefficient (this class)"),
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

    final v = double.tryParse(note.text.trim().replaceAll(',', '.'));
    final c = double.tryParse(coef.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 20) {
      _snack("The grade must be between 0 and 20");
      return;
    }
    if (c == null || c <= 0) {
      _snack("Invalid coefficient");
      return;
    }

    final headers = {'Content-Type': 'application/json'};
    try {
      // 1) coefficient de la matière pour la classe
      await http.post(Uri.parse("$baseUrl/api/classmats"),
          headers: headers,
          body: json.encode({
            'classe': {'codClass': classId},
            'matiere': {'codMat': codMat},
            'coef': c,
          }));

      // 2) la note
      final body = json.encode({
        'valeurNote': v,
        'matiere': {'codMat': codMat},
        'etudiant': {'id': s.id},
      });
      final res = g == null
          ? await http.post(Uri.parse("$baseUrl/api/notes"),
          headers: headers, body: body)
          : await http.put(Uri.parse("$baseUrl/api/notes/${g.id}"),
          headers: headers, body: body);
      if (res.statusCode != 200) {
        _snack("Save failed (${res.statusCode})");
        return;
      }
      await loadGrades();
    } catch (_) {
      _snack("Cannot reach the server");
    }
  }

  Future<void> deleteGrade(GradeRow g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete grade?"),
        content: Text("${g.codMat} : ${fmtNum(g.note)} / 20"),
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
      await http.delete(Uri.parse("$baseUrl/api/notes/${g.id}"));
      await loadGrades();
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

  Widget _table() {
    if (rows.isEmpty) {
      return const Center(child: Text("No grades for this student"));
    }
    final admin = Session.isAdmin;
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEDEBFF)),
          columns: [
            const DataColumn(label: Text("CodMat")),
            const DataColumn(label: Text("Grade"), numeric: true),
            const DataColumn(label: Text("Coef"), numeric: true),
            const DataColumn(label: Text("Grade × Coef"), numeric: true),
            if (admin) const DataColumn(label: Text("")),
          ],
          rows: rows
              .map((g) => DataRow(cells: [
            DataCell(Text(g.codMat)),
            DataCell(Text(fmtNum(g.note))),
            DataCell(Text(fmtNum(g.coef))),
            DataCell(Text(fmtNum(g.note * g.coef))),
            if (admin)
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: kPrimary),
                    onPressed: () => gradeDialog(g: g)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteGrade(g)),
              ])),
          ]))
              .toList(),
        ),
      ),
    );
  }

  // carte de résultat : détail du calcul + moyenne
  Widget _averageCard() {
    double sumNC = 0, sumC = 0;
    for (final g in rows) {
      sumNC += g.note * g.coef;
      sumC += g.coef;
    }
    final avg = moyenne;
    final passed = avg != null && avg >= 10;
    final color = avg == null
        ? Colors.grey
        : (passed ? Colors.green.shade700 : Colors.red.shade700);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avg != null)
            Text("Σ(grade × coef) / Σ(coef) = ${fmtNum(sumNC)} / ${fmtNum(sumC)}",
                style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            avg == null ? "Average : -" : "Average : ${avg.toStringAsFixed(2)} / 20",
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color),
          ),
          if (avg != null)
            Text(passed ? "Passed" : "Failed",
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = currentStudent;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grades & average"),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: Session.isAdmin
          ? FloatingActionButton(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          onPressed: () => gradeDialog(),
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
                  await loadGrades();
                }),
              ),
            ]),
          ),
          if (s != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("${s.nom} ${s.prenom}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimary)),
              ),
            ),
          const Divider(),
          Expanded(child: _table()),
          _averageCard(),
        ],
      ),
    );
  }
}