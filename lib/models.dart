String fmtNum(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

// "2025-11-11" -> "11-11-2025"
String fmtDate(String iso) {
  if (iso.length < 10) return iso;
  return "${iso.substring(8, 10)}-${iso.substring(5, 7)}-${iso.substring(0, 4)}";
}

class Departement {
  int codDept;
  String nomDept;
  Departement(this.codDept, this.nomDept);

  factory Departement.fromMap(Map<String, dynamic> m) =>
      Departement(m['codDept'], m['nomDept'] ?? '');
}

class Matiere {
  String codMat;
  String intMat;
  Matiere(this.codMat, this.intMat);

  factory Matiere.fromMap(Map<String, dynamic> m) =>
      Matiere(m['codMat'], m['intMat'] ?? '');
}

class Classe {
  int codClass;
  String nomClass;
  int nbreEtud;
  int? codDept;
  String? nomDept;
  Classe(this.codClass, this.nomClass, this.nbreEtud,
      {this.codDept, this.nomDept});

  factory Classe.fromMap(Map<String, dynamic> m) {
    final d = m['departement'];
    return Classe(
      m['codClass'],
      m['nomClass'] ?? '',
      m['nbreEtud'] ?? 0,
      codDept: d is Map ? d['codDept'] : null,
      nomDept: d is Map ? d['nomDept'] : null,
    );
  }
}

class Formation {
  int id;
  String nom;
  int duree;
  Formation(this.id, this.nom, this.duree);

  factory Formation.fromMap(Map<String, dynamic> m) =>
      Formation(m['id'], m['nom'] ?? '', m['duree'] ?? 0);
}

class Etudiant {
  int? id;
  String? nce;
  String nom;
  String prenom;
  String? dateNais; // "yyyy-MM-dd"
  String? lieuNais;
  int? formationId;
  String? formationNom;

  Etudiant(this.id, this.nom, this.prenom,
      {this.nce,
        this.dateNais,
        this.lieuNais,
        this.formationId,
        this.formationNom});

  // ce qu'on affiche comme code étudiant (E1...)
  String get code => (nce != null && nce!.isNotEmpty) ? nce! : '#$id';

  factory Etudiant.fromMap(Map<String, dynamic> m) {
    final f = m['formation'];
    return Etudiant(
      m['id'],
      m['nom'] ?? '',
      m['prenom'] ?? '',
      nce: m['nce'],
      dateNais: m['dateNais'] is String ? m['dateNais'] : null,
      lieuNais: m['lieuNais'],
      formationId: f is Map ? f['id'] : null,
      formationNom: f is Map ? f['nom'] : null,
    );
  }
}

class Absence {
  int? id;
  String codMat;
  String dateA; // "yyyy-MM-dd"
  double nha;
  Absence(this.id, this.codMat, this.dateA, this.nha);

  factory Absence.fromMap(Map<String, dynamic> m) => Absence(
    m['id'],
    m['matiere']['codMat'],
    m['dateA'] ?? '',
    (m['nha'] as num?)?.toDouble() ?? 0,
  );
}

class GradeRow {
  int id;
  String codMat;
  String intMat;
  double note;
  double coef;
  GradeRow(this.id, this.codMat, this.intMat, this.note, this.coef);

  factory GradeRow.fromMap(Map<String, dynamic> m) => GradeRow(
    m['id'],
    m['codMat'],
    m['intMat'] ?? '',
    (m['note'] as num).toDouble(),
    (m['coef'] as num).toDouble(),
  );
}