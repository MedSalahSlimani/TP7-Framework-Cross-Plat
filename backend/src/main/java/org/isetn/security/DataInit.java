package org.isetn.security;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;
import org.isetn.entities.*;
import org.isetn.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.core.annotation.Order;

@Component
@Order(1)
public class DataInit implements CommandLineRunner {

    private final AppRoleRepository roleRepo;
    private final AppUserRepository userRepo;
    private final DepartementRepository departementRepo;
    private final MatiereRepository matiereRepo;
    private final ClasseRepository classeRepo;
    private final EtudiantRepository etudiantRepo;
    private final AbsenceRepository absenceRepo;
    private final PasswordEncoder encoder;

    public DataInit(AppRoleRepository roleRepo, AppUserRepository userRepo,
                    DepartementRepository departementRepo, MatiereRepository matiereRepo,
                    ClasseRepository classeRepo, EtudiantRepository etudiantRepo,
                    AbsenceRepository absenceRepo, PasswordEncoder encoder) {
        this.roleRepo = roleRepo;
        this.userRepo = userRepo;
        this.departementRepo = departementRepo;
        this.matiereRepo = matiereRepo;
        this.classeRepo = classeRepo;
        this.etudiantRepo = etudiantRepo;
        this.absenceRepo = absenceRepo;
        this.encoder = encoder;
    }

    private AppRole role(String name) {
        AppRole r = roleRepo.findByRoleName(name);
        if (r == null) {
            r = new AppRole();
            r.setRoleName(name);
            r = roleRepo.save(r);
        }
        return r;
    }

    @Override
    public void run(String... args) {
        // 1. ROLES ET UTILISATEURS
        AppRole admin = role("ADMIN");
        AppRole user = role("USER");

        if (userRepo.findByUsername("admin@gmail.com") == null) {
            Set<AppRole> roles = new HashSet<>();
            roles.add(admin);
            roles.add(user);

            AppUser u = new AppUser();
            u.setUsername("admin@gmail.com");
            u.setPassword(encoder.encode("admin"));
            // Changez setActive par setActivated 👇
            u.setActived(true); 
            u.setRoles(roles);
            userRepo.save(u);
        }

        // 2. DEPARTEMENTS
        if (departementRepo.count() == 0) {
            Departement dTI = new Departement();
            dTI.setCodDept("TI");
            dTI.setNomDept("Technologies de l'Informatique");
            departementRepo.save(dTI);

            Departement dGE = new Departement();
            dGE.setCodDept("GE");
            dGE.setNomDept("Génie Électrique");
            departementRepo.save(dGE);

            // 3. CLASSES
            Classe cDSI33 = new Classe();
            cDSI33.setCodClass("DSI33");
            cDSI33.setNomClass("Développement Systèmes d'Information 3");
            cDSI33.setNbrEtud(0);
            cDSI33.setDepartement(dTI);
            classeRepo.save(cDSI33);

            // 4. MATIERES
            Matiere matAFCP = new Matiere();
            matAFCP.setCodMat("AFCP");
            matAFCP.setIntMat("Atelier Framework Cross Plateforme");
            matAFCP.setDescription("");
            matiereRepo.save(matAFCP);

            Matiere matSOA = new Matiere();
            matSOA.setCodMat("SOA");
            matSOA.setIntMat("Applications Orientées Services");
            matSOA.setDescription("");
            matiereRepo.save(matSOA);

            // 5. ETUDIANTS
            Etudiant e1 = new Etudiant();
            e1.setNce("E1");
            e1.setNom("Ben Foulen1");
            e1.setPrenom("Foulen1");
            e1.setDateNais(LocalDate.now());
            e1.setLieuNais("Tunis");
            e1.setClasse(cDSI33);
            etudiantRepo.save(e1);

            Etudiant e2 = new Etudiant();
            e2.setNce("E2");
            e2.setNom("Ben Foulen2");
            e2.setPrenom("Foulen2");
            e2.setDateNais(LocalDate.now());
            e2.setLieuNais("Tunis");
            e2.setClasse(cDSI33);
            etudiantRepo.save(e2);

            // 6. ABSENCES (Pour tester la Q1 de l'examen)
            Absence a1 = new Absence();
            a1.setMatiere(matAFCP);
            a1.setEtudiant(e1);
            a1.setDateA(LocalDate.of(2025, 11, 18));
            a1.setNha(1.5);
            absenceRepo.save(a1);

            Absence a2 = new Absence();
            a2.setMatiere(matAFCP);
            a2.setEtudiant(e2);
            a2.setDateA(LocalDate.of(2025, 11, 18));
            a2.setNha(3.0);
            absenceRepo.save(a2);
        }
    }
}