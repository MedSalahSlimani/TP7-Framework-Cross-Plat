package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Etudiant;
import org.isetn.repository.AbsenceRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.NoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/etudiants")
public class EtudiantController {
    @Autowired
    private EtudiantRepository etudiantRepository;
    @Autowired
    private AbsenceRepository absenceRepository;

    @Autowired
    private NoteRepository noteRepository;   // à ajouter avec les autres @Autowired

    @GetMapping("/classe/{codClass}")
    public List<Etudiant> getEtudiantsByClasse(@PathVariable String codClass) {
        return etudiantRepository.findByClasseCodClass(codClass); 
    }

    @PostMapping
    public Etudiant add(@RequestBody Etudiant e) {
        return etudiantRepository.save(e);
    }

    @PutMapping("/{id}")
    public Etudiant update(@PathVariable Long id, @RequestBody Etudiant e) {
        e.setId(id);
        return etudiantRepository.save(e);
    }

    @Transactional
    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        absenceRepository.deleteByEtudiantId(id);
        noteRepository.deleteByEtudiantId(id);    
        etudiantRepository.deleteById(id);
        
    }
}




