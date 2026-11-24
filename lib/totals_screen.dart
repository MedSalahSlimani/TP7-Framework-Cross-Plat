import 'dart:convert';
import 'package:flutter/material.dart';
import 'auth_http.dart' as http;
import 'api.dart';
import 'absence_chart.dart';
import 'auth_widgets.dart';
import 'models.dart';

class TotalsScreen extends StatefulWidget {
  final Etudiant etudiant;
  final String classe;
  final String dept;

  const TotalsScreen({
    Key? key,
    required this.etudiant,
    required this.classe,
    required this.dept,
  }) : super(key: key);

  @override
  State<TotalsScreen> createState() => _TotalsScreenState();
}

class _TotalsScreenState extends State<TotalsScreen> {
  late Future<List<MapEntry<String, double>>> future;

  @override
  void initState() {
    super.initState();
    future = fetch();
  }

  Future<List<MapEntry<String, double>>> fetch() async {
    final res = await http
        .get(Uri.parse("$baseUrl/api/absences/total/${widget.etudiant.id}"));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data
        .map((e) => MapEntry<String, double>(
        e['codMat'] as String, (e['total'] as num).toDouble()))
        .toList();
  }

  Widget _kv(String k, String v) => Text.rich(TextSpan(children: [
    TextSpan(
        text: "$k : ",
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: kPrimary, fontSize: 16)),
    TextSpan(text: v, style: const TextStyle(fontSize: 16)),
  ]));

  @override
  Widget build(BuildContext context) {
    final e = widget.etudiant;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Total absences"),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<MapEntry<String, double>>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text("Cannot reach the server"));
          }
          final list = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // en-tête : classe, département, étudiant, nom, prénom
              Wrap(
                spacing: 24,
                runSpacing: 6,
                children: [
                  _kv("Classe", widget.classe),
                  _kv("Département", widget.dept),
                  _kv("Etudiant", e.code),
                  _kv("Nom", e.nom),
                  _kv("Prénom", e.prenom),
                ],
              ),
              const SizedBox(height: 20),
              // tableau CodMat / Total NHA
              if (list.isEmpty)
                const Center(child: Text("No absences for this student"))
              else
                Center(
                  child: DataTable(
                    border: TableBorder.all(color: Colors.black54),
                    headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFEDEBFF)),
                    columns: const [
                      DataColumn(
                          label: Text("CodMat",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Total NHA",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          numeric: true),
                    ],
                    rows: list
                        .map((m) => DataRow(cells: [
                      DataCell(Text(m.key)),
                      DataCell(Text(fmtNum(m.value))),
                    ]))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 28),
              const Text("Absences per subject",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AbsenceChart(
                    labels: list.map((m) => m.key).toList(),
                    values: list.map((m) => m.value).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}