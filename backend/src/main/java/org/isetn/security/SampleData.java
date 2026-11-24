package org.isetn.security;

import java.time.LocalDate;
import org.isetn.entities.Absence;
import org.isetn.entities.Classe;
import org.isetn.entities.Departement;
import org.isetn.entities.Etudiant;
import org.isetn.entities.Matiere;
import org.isetn.repository.AbsenceRepository;
import org.isetn.repository.ClasseRepository;
import org.isetn.repository.DepartementRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.MatiereRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.core.annotation.Order;

@Component
@Order(2)
public class SampleData implements CommandLineRunner {
    
    private final DepartementRepository deptRepo;
    private final ClasseRepository classeRepo;
    private final EtudiantRepository etudiantRepo;
    private final MatiereRepository matiereRepo;
    private final AbsenceRepository absenceRepo;

    public SampleData(DepartementRepository deptRepo, ClasseRepository classeRepo,
                      EtudiantRepository etudiantRepo, MatiereRepository matiereRepo,
                      AbsenceRepository absenceRepo) {
        this.deptRepo = deptRepo;
        this.classeRepo = classeRepo;
        this.etudiantRepo = etudiantRepo;
        this.matiereRepo = matiereRepo;
        this.absenceRepo = absenceRepo;
    }

    // ---------- petites méthodes utilitaires

    private Departement dept(String nom) {
        return deptRepo.findAll().stream()
                .filter(d -> nom.equals(d.getNomDept()))
                .findFirst()
                .orElseGet(() -> deptRepo.save(new Departement(null, nom)));
    }

    private Matiere matiere(String cod, String intitule) {
        return matiereRepo.findById(cod)
                .orElseGet(() -> matiereRepo.save(new Matiere(cod, intitule, "")));
    }

    private Classe classe(String nom, Departement d) {
        return classeRepo.save(new Classe(null, nom, d, null));
    }

    private Etudiant etu(String nce, String nom, String prenom, String dateNais,
                         String lieu, Classe c) {
        return etudiantRepo.save(new Etudiant(null, nce, nom, prenom,
                LocalDate.parse(dateNais), lieu, c, null));
    }

    private void abs(Etudiant e, Matiere m, String date, double heures) {
        absenceRepo.save(new Absence(null, m, e, LocalDate.parse(date), heures));
    }

    // ---------- données

    @Override
    public void run(String... args) {
        // on remplit seulement une base vide (évite les doublons à chaque démarrage)
        if (classeRepo.count() > 0 || etudiantRepo.count() > 0) return;

        Departement ti = dept("TI");
        Departement ge = dept("GE");
        dept("GM");

        Matiere afcp = matiere("AFCP", "Atelier Framework Cross Plateforme");
        Matiere soa = matiere("SOA", "Applications Orientées Services");
        Matiere mob = matiere("DEVMOB", "Développement Mobile");
        Matiere big = matiere("BIGDATA", "Gestion des données massives");
        Matiere meth = matiere("METHCONC", "Méthodologie de conception");
        Matiere ml = matiere("ML", "Machine Learning appliqué");

        Classe dsi33 = classe("DSI33", ti);
        Classe dsi31 = classe("DSI31", ti);
        Classe dsi32 = classe("DSI32", ti);
        Classe ge21 = classe("GE21", ge);

        // ----- DSI33
        Etudiant e1 = etu("E1", "salah", "slimani", "2003-05-14", "Nabeul", dsi33);
        Etudiant e2 = etu("E2", "Trabelsi", "Yassine", "2003-09-02", "Hammamet", dsi33);
        Etudiant e3 = etu("E3", "Gharbi", "Meriem", "2004-01-21", "Nabeul", dsi33);
        Etudiant e4 = etu("E4", "Jlassi", "Ahmed", "2003-11-30", "Tunis", dsi33);
        etu("E5", "Mejri", "Salma", "2004-03-08", "Sousse", dsi33); // sans absence

        // ----- DSI31
        Etudiant e6 = etu("E6", "Ben Salah", "Rania", "2003-07-19", "Nabeul", dsi31);
        Etudiant e7 = etu("E7", "Hammami", "Oussama", "2003-02-11", "Bizerte", dsi31);
        etu("E8", "Chaabane", "Ines", "2004-06-25", "Sfax", dsi31);

        // ----- DSI32
        Etudiant e9 = etu("E9", "Dridi", "Mohamed Amine", "2003-12-05", "Kélibia", dsi32);
        Etudiant e10 = etu("E10", "Khelifi", "Sirine", "2004-04-17", "Nabeul", dsi32);

        // ----- GE21
        Etudiant e11 = etu("E11", "Mansouri", "Hatem", "2003-08-23", "Monastir", ge21);
        etu("E12", "Ayari", "Nour", "2004-02-14", "Tunis", ge21);

        // ----- absences de E1 (exactement celles du PDF : AFCP = 6, SOA = 7.5)
        abs(e1, afcp, "2025-11-11", 1.5);
        abs(e1, afcp, "2025-10-04", 4.5);
        abs(e1, soa, "2025-10-20", 1.5);
        abs(e1, soa, "2025-10-23", 3);
        abs(e1, soa, "2025-10-16", 3);

        // ----- autres étudiants
        abs(e2, afcp, "2025-10-07", 3);
        abs(e2, afcp, "2025-11-18", 1.5);
        abs(e2, mob, "2025-10-14", 1.5);
        abs(e2, big, "2025-11-04", 3);

        abs(e3, soa, "2025-10-09", 1.5);
        abs(e3, meth, "2025-10-21", 3);
        abs(e3, mob, "2025-11-06", 4.5);
        abs(e3, mob, "2025-11-13", 1.5);

        abs(e4, ml, "2025-10-15", 3);
        abs(e4, afcp, "2025-11-03", 1.5);

        abs(e6, afcp, "2025-10-10", 3);
        abs(e6, soa, "2025-10-24", 1.5);
        abs(e6, big, "2025-11-07", 3);

        abs(e7, mob, "2025-10-17", 4.5);
        abs(e7, soa, "2025-11-14", 3);

        abs(e9, meth, "2025-10-13", 1.5);
        abs(e9, afcp, "2025-10-27", 3);

        abs(e10, ml, "2025-11-05", 1.5);

        abs(e11, afcp, "2025-10-22", 3);
    }
}