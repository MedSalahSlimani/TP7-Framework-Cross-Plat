import 'package:flutter/material.dart';
import 'api.dart';

class AbsencesClassMatScreen extends StatefulWidget {
  @override
  _AbsencesClassMatScreenState createState() => _AbsencesClassMatScreenState();
}

class _AbsencesClassMatScreenState extends State<AbsencesClassMatScreen> {
  String? selectedClasse = "DSI33"; 
  String? selectedMat = "AFCP";
  List<dynamic> absences = [];
  bool isLoading = false;

  void _loadData() async {
    setState(() { isLoading = true; });
    try {
      var data = await fetchAbsencesByClasseMat(selectedClasse!, selectedMat!);
      setState(() { absences = data; isLoading = false; });
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Absences par Classe/Matière")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(
                  decoration: InputDecoration(labelText: "Classe (ex: DSI33)"),
                  onChanged: (val) => selectedClasse = val,
                )),
                SizedBox(width: 10),
                Expanded(child: TextField(
                  decoration: InputDecoration(labelText: "Matière (ex: AFCP)"),
                  onChanged: (val) => selectedMat = val,
                )),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadData,
              child: Text("Rechercher"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Prénom')),
                    DataColumn(label: Text('NHA')),
                  ],
                  rows: absences.map((abs) {
                    return DataRow(cells: [
                      DataCell(Text(abs['nom'] ?? '')),
                      DataCell(Text(abs['prenom'] ?? '')),
                      DataCell(Text(abs['nha'].toString())),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}