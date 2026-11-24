import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'api.dart';
import 'auth_widgets.dart';
import 'models.dart';
import 'session.dart';

Widget _kv(String k, String v) => Text.rich(TextSpan(children: [
  TextSpan(
      text: "$k : ",
      style: const TextStyle(
          fontWeight: FontWeight.bold, color: kPrimary, fontSize: 16)),
  TextSpan(text: v, style: const TextStyle(fontSize: 16)),
]));

class ExamScreen extends StatelessWidget {
  const ExamScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Exam"),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "1. Absences"),
              Tab(text: "2. Biggest class"),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _AbsencesTab(),
          _BiggestTab(),
        ]),
      ),
    );
  }
}

// ======================= Question 1 : absences d'une classe =======================

class _AbsencesTab extends StatefulWidget {
  const _AbsencesTab();
  @override
  State<_AbsencesTab> createState() => _AbsencesTabState();
}

class _AbsencesTabState extends State<_AbsencesTab> {
  List<Classe> classes = [];
  List<Matiere> matieres = [];
  int? classId;
  String? codMat;
  String date = DateTime.now().toIso8601String().substring(0, 10);
  Map<String, dynamic>? result;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<List> _list(String path) async {
    final res = await http.get(Uri.parse("$baseUrl$path"));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as List;
  }

  Future<void> init() async {
    try {
      classes = (await _list("/api/classes")).map((e) => Classe.fromMap(e)).toList();
      matieres = (await _list("/api/matieres")).map((e) => Matiere.fromMap(e)).toList();
      if (classes.isNotEmpty) classId = classes.first.codClass;
      if (matieres.isNotEmpty) codMat = matieres.first.codMat;
      await load();
    } catch (_) {
      error = true;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> load() async {
    if (classId == null || codMat == null) return;
    final res = await http.get(Uri.parse(
        "$baseUrl/api/exam/absences?codClass=$classId&codMat=$codMat&date=$date"));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    result = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (mounted) setState(() {});
  }

  Future<void> reload() async {
    try {
      await load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cannot reach the server"),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => date = d.toIso8601String().substring(0, 10));
      reload();
    }
  }

  Widget _box(String label, Widget dropdown) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: DropdownButtonHideUnderline(child: dropdown),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error) return const Center(child: Text("Cannot reach the server"));

    final r = result;
    final rows = r == null ? <dynamic>[] : (r['rows'] as List);
    final chsm = (r?['chsm'] as num?)?.toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
            child: _box(
              "Classe",
              DropdownButton<int>(
                isExpanded: true,
                isDense: true,
                value: classId,
                items: classes
                    .map((c) => DropdownMenuItem(
                    value: c.codClass,
                    child: Text(c.nomDept == null
                        ? c.nomClass
                        : "${c.nomClass} (${c.nomDept})")))
                    .toList(),
                onChanged: (v) {
                  setState(() => classId = v);
                  reload();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _box(
              "Matière",
              DropdownButton<String>(
                isExpanded: true,
                isDense: true,
                value: codMat,
                items: matieres
                    .map((m) =>
                    DropdownMenuItem(value: m.codMat, child: Text(m.codMat)))
                    .toList(),
                onChanged: (v) {
                  setState(() => codMat = v);
                  reload();
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text("Date : ${fmtDate(date)}"),
          onPressed: pickDate,
        ),
        if (r != null) ...[
          const Divider(height: 32),
          Wrap(spacing: 24, runSpacing: 6, children: [
            _kv("Classe", "${r['classe']}"),
            _kv("Département", "${r['departement'] ?? '-'}"),
            _kv("Matière", "${r['matiere']}"),
            _kv("CHSM", chsm == null ? "-" : "${fmtNum(chsm)} heures"),
            _kv("Date", fmtDate(date)),
          ]),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Center(child: Text("No absences on this date"))
          else
            DataTable(
              border: TableBorder.all(color: Colors.black54),
              headingRowColor: WidgetStateProperty.all(const Color(0xFFEDEBFF)),
              columns: const [
                DataColumn(label: Text("Nom", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Prenom", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("NHA", style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true),
              ],
              rows: rows
                  .map<DataRow>((e) => DataRow(cells: [
                DataCell(Text("${e['nom']}")),
                DataCell(Text("${e['prenom']}")),
                DataCell(Text(fmtNum((e['nha'] as num).toDouble()))),
              ]))
                  .toList(),
            ),
        ],
      ],
    );
  }
}

// ======================= Question 2 : classe la plus nombreuse =======================

class _BiggestTab extends StatefulWidget {
  const _BiggestTab();
  @override
  State<_BiggestTab> createState() => _BiggestTabState();
}

class _BiggestTabState extends State<_BiggestTab> {
  Map<String, dynamic>? data;
  bool loading = true;
  bool error = false;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> load() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/exam/biggest-class"));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      error = true;
    }
    if (mounted) setState(() => loading = false);
  }

  // met à jour la colonne NbrEtud de cette classe dans la table Classe
  Future<void> update() async {
    setState(() => updating = true);
    try {
      final res = await http.put(Uri.parse("$baseUrl/api/exam/update-nbr-etud"));
      if (res.statusCode == 200) {
        data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _snack("NbrEtud updated in table Classe", color: Colors.green);
      } else if (res.statusCode == 403) {
        _snack("Only an administrator can update");
      } else {
        _snack("Update failed (${res.statusCode})");
      }
    } catch (_) {
      _snack("Cannot reach the server");
    }
    if (mounted) setState(() => updating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error || data == null) {
      return const Center(child: Text("No class found or server unreachable"));
    }
    final d = data!;
    final stored = d['nbrEtud'];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 56, color: kPrimary),
                const SizedBox(height: 8),
                const Text("Class with the most students",
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Text("${d['nomClass']}",
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold, color: kPrimary)),
                const SizedBox(height: 12),
                _kv("Département", "${d['departement'] ?? '-'}"),
                const SizedBox(height: 6),
                _kv("Students (counted in table Etudiant)", "${d['nbEtudiants']}"),
                const SizedBox(height: 6),
                _kv("NbrEtud (stored in table Classe)",
                    stored == null ? "not set yet" : "$stored"),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: updating ? null : update,
                  icon: updating
                      ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: const Text("Update NbrEtud"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                if (!Session.isAdmin)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("Administrator account required",
                        style: TextStyle(color: Colors.black45, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}