import 'dart:convert';
import 'package:http/http.dart' as http;

// Remplacez par votre IP (ex: http://10.0.2.2:8080 pour l'émulateur)
final String baseUrl = "http://10.0.2.2:8080/api/exam";

Future<List<dynamic>> fetchAbsencesByClasseMat(String codClass, String codMat) async {
  final response = await http.get(Uri.parse('$baseUrl/absences/$codClass/$codMat'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Erreur de chargement');
  }
}

Future<Map<String, dynamic>> fetchTopClasse() async {
  final response = await http.get(Uri.parse('$baseUrl/top-classe'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Erreur de chargement');
  }
}

Future<void> updateClasseNbrEtud(String codClass, int count) async {
  final response = await http.put(Uri.parse('$baseUrl/update-nbr-etud/$codClass/$count'));
  if (response.statusCode != 200) {
    throw Exception('Erreur lors de la mise à jour');
  }
}