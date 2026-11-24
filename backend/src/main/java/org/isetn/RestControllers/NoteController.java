package org.isetn.RestControllers;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.isetn.entities.ClassMat;
import org.isetn.entities.Etudiant;
import org.isetn.entities.Note;
import org.isetn.repository.ClassMatRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.MatiereRepository;
import org.isetn.repository.NoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/notes")
public class NoteController {
    @Autowired
    private NoteRepository noteRepository;
    @Autowired
    private ClassMatRepository classMatRepository;
    @Autowired
    private MatiereRepository matiereRepository;
    @Autowired
    private EtudiantRepository etudiantRepository;

    // notes d'un étudiant + sa moyenne pondérée
    @GetMapping("/etudiant/{etudiantId}")
    public Map<String, Object> byEtudiant(@PathVariable Long etudiantId) {
        Etudiant e = etudiantRepository.findById(etudiantId).orElseThrow();

        List<Map<String, Object>> rows = new ArrayList<>();
        double sumNoteCoef = 0;
        double sumCoef = 0;

        for (Note n : noteRepository.findByEtudiantIdOrderByMatiereCodMat(etudiantId)) {
            double coef = 1.0; // coef par défaut si la matière n'est pas liée à la classe
            if (e.getClasse() != null) {
                ClassMat cm = classMatRepository.findByClasseCodClassAndMatiereCodMat(  
                    
                   
                        e.getClasse().getCodClass(), n.getMatiere().getCodMat());
                if (cm != null && cm.getCoef() != null) coef = cm.getCoef();
            }
            double v = n.getValeurNote() == null ? 0 : n.getValeurNote();
            sumNoteCoef += v * coef;
            sumCoef += coef;

            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", n.getId());
            row.put("codMat", n.getMatiere().getCodMat());
            row.put("intMat", n.getMatiere().getIntMat());
            row.put("note", v);
            row.put("coef", coef);
            rows.add(row);
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("notes", rows);
        res.put("totalCoef", sumCoef);
        res.put("moyenne", sumCoef == 0 ? null : Math.round(sumNoteCoef / sumCoef * 100.0) / 100.0);
        return res;
    }

    // ajoute une note (si l'étudiant a déjà une note dans cette matière, elle est remplacée)
    @PostMapping
    public Note add(@RequestBody Note n) {
        n.setId(null);
        resolve(n);
        for (Note old : noteRepository.findByEtudiantIdOrderByMatiereCodMat(n.getEtudiant().getId())) {
            if (old.getMatiere().getCodMat().equals(n.getMatiere().getCodMat())) {
                n.setId(old.getId());
                break;
            }
        }
        return noteRepository.save(n);
    }

    @PutMapping("/{id}")
    public Note update(@PathVariable Long id, @RequestBody Note n) {
        n.setId(id);
        resolve(n);
        return noteRepository.save(n);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        noteRepository.deleteById(id);
    }

    private void resolve(Note n) {
        if (n.getValeurNote() == null || n.getValeurNote() < 0 || n.getValeurNote() > 20) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La note doit être entre 0 et 20");
        }
        n.setMatiere(matiereRepository.findById(n.getMatiere().getCodMat()).orElseThrow());
        n.setEtudiant(etudiantRepository.findById(n.getEtudiant().getId()).orElseThrow());
    }
}