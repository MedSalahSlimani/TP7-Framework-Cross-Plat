package org.isetn.RestControllers;

import org.isetn.entities.Classe;
import org.isetn.entities.Etudiant;
import org.isetn.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/classes")
public class ClasseController {

    @Autowired
    private ClasseRepository classeRepository;
    @Autowired
    private EtudiantRepository etudiantRepository;
    @Autowired
    private AbsenceRepository absenceRepository;
    @Autowired
    private NoteRepository noteRepository;
    @Autowired
    private ClassMatRepository classMatRepository;

    // 1. Calculer et mettre à jour le nombre d'étudiants d'une classe
    @PutMapping("/update-count/{codClass}")
    public Classe updateNbrEtud(@PathVariable String codClass) {
        Classe c = classeRepository.findById(codClass).orElseThrow();
        
    
        long count = etudiantRepository.countByClasseCodClass(codClass);
        c.setNbrEtud((int) count);
        
        return classeRepository.save(c);
    }

    // 2. Récupérer les classes par département
    @GetMapping("/departement/{codDept}")
    public List<Classe> getClassesByDepartement(@PathVariable String codDept) {

        return classeRepository.findByDepartementCodDept(codDept);

    }

    @Transactional
    @DeleteMapping("/{id}")
    public void delete(@PathVariable String id) {
        // a. Supprimer les absences et notes des étudiants de cette classe
        for (Etudiant e : etudiantRepository.findByClasseCodClass(id)) {
absenceRepository.deleteByEtudiantId(e.getId()); 
noteRepository.deleteByEtudiantId(e.getId());
        }
        
        // b. Supprimer les matières de la classe (ClassMat)
        classMatRepository.deleteByClasseCodClass(id);
        
        // c. Supprimer les étudiants
        etudiantRepository.deleteByClasseCodClass(id);
        
        // d. Enfin, supprimer la classe
        classeRepository.deleteById(id);
    }
}


