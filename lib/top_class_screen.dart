import 'package:flutter/material.dart';
import 'api.dart';

class TopClassScreen extends StatefulWidget {
  @override
  _TopClassScreenState createState() => _TopClassScreenState();
}

class _TopClassScreenState extends State<TopClassScreen> {
  Map<String, dynamic>? topClasse;
  bool isLoading = false;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadTopClasse();
  }

  void _loadTopClasse() async {
    setState(() { isLoading = true; });
    try {
      var data = await fetchTopClasse();
      setState(() { topClasse = data; isLoading = false; });
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _updateDatabase() async {
    if (topClasse == null) return;
    setState(() { isUpdating = true; });
    try {
      await updateClasseNbrEtud(topClasse!['codClass'], topClasse!['count']);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Base de données mise à jour !")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() { isUpdating = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Classe avec le plus d'étudiants")),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : topClasse == null
            ? Text("Aucune donnée")
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Classe : ${topClasse!['codClass']}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Nombre d'étudiants (calculé) : ${topClasse!['count']}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            isUpdating
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
              icon: Icon(Icons.update),
              label: Text("Mettre à jour la table Classe"),
              onPressed: _updateDatabase,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}