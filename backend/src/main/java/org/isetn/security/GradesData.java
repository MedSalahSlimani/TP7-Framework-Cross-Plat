package org.isetn.security;

import org.isetn.entities.ClassMat;
import org.isetn.entities.Classe;
import org.isetn.entities.Etudiant;
import org.isetn.entities.Matiere;
import org.isetn.entities.Note;
import org.isetn.repository.ClassMatRepository;
import org.isetn.repository.ClasseRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.MatiereRepository;
import org.isetn.repository.NoteRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;



@Component
@Order(3)
public class GradesData implements CommandLineRunner {

    // ordre des matières, des coefs et des notes
    private static final String[] MATS = {"AFCP", "SOA", "DEVMOB", "BIGDATA", "METHCONC", "ML"};
    private static final double[] COEF = {2, 1.5, 2, 1.5, 1, 2};
    private static final double[] CHSM = {42, 21, 42, 21, 21, 21};

    private final ClasseRepository classeRepo;
    private final EtudiantRepository etudiantRepo;
    private final MatiereRepository matiereRepo;
    private final ClassMatRepository classMatRepo;
    private final NoteRepository noteRepo;

    public GradesData(ClasseRepository classeRepo, EtudiantRepository etudiantRepo,
                      MatiereRepository matiereRepo, ClassMatRepository classMatRepo,
                      NoteRepository noteRepo) {
        this.classeRepo = classeRepo;
        this.etudiantRepo = etudiantRepo;
        this.matiereRepo = matiereRepo;
        this.classMatRepo = classMatRepo;
        this.noteRepo = noteRepo;
    }

    private void notes(String nce, double... valeurs) {
        Etudiant e = etudiantRepo.findAll().stream()
                .filter(x -> nce.equals(x.getNce()))
                .findFirst().orElse(null);
        if (e == null) return;
        for (int i = 0; i < valeurs.length; i++) {
            final double v = valeurs[i];
            matiereRepo.findById(MATS[i])
                    .ifPresent(m -> noteRepo.save(new Note(null, e, m, v)));
        }
    }

    @Override
    public void run(String... args) {
        if (noteRepo.count() > 0 || classMatRepo.count() > 0) return;

        // coefficients et charge horaire pour les classes du département TI
        for (Classe c : classeRepo.findAll()) {
            if (c.getDepartement() == null || !"TI".equals(c.getDepartement().getNomDept())) continue;
            for (int i = 0; i < MATS.length; i++) {
                Matiere m = matiereRepo.findById(MATS[i]).orElse(null);
                if (m == null) continue;
                classMatRepo.save(new ClassMat(null, m, c, COEF[i], CHSM[i]));
            }
        }

        //            AFCP  SOA   DEVMOB BIGDATA METHCONC ML
        notes("E1", 14.5, 12, 16, 12, 12.5, 15);
        notes("E2", 10, 9.5, 12, 8, 11, 13);
        notes("E3", 16, 15.5, 14, 17, 15, 16.5);
        notes("E4", 8, 7, 10, 9.5, 12, 6.5);
        notes("E6", 12, 13.5, 11, 14, 10, 12.5);
        notes("E7", 9, 11, 8.5, 10, 9.5, 11);
        notes("E9", 13, 12, 14.5, 11, 13.5, 12);
    }
}