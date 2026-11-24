package org.isetn.RestControllers;

import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import org.isetn.entities.Absence;
import org.isetn.repository.AbsenceRepository;
import org.isetn.repository.EtudiantRepository;
import org.isetn.repository.MatiereRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/absences")
public class AbsenceController {
    @Autowired
    private AbsenceRepository absenceRepository;
    @Autowired
    private MatiereRepository matiereRepository;
    @Autowired
    private EtudiantRepository etudiantRepository;

    // toutes les absences d'un étudiant
    @GetMapping("/etudiant/{etudiantId}")
    public List<Absence> byEtudiant(@PathVariable Long etudiantId) {
        return absenceRepository.findByEtudiantIdOrderByDateADesc(etudiantId);
    }

    // total des heures d'absence par matière pour un étudiant
    @GetMapping("/total/{etudiantId}")
    public List<Map<String, Object>> total(@PathVariable Long etudiantId) {
        Map<String, Double> totals = new TreeMap<>();
        for (Absence a : absenceRepository.findByEtudiantId(etudiantId)) {
            double h = a.getNha() == null ? 0 : a.getNha();
            totals.merge(a.getMatiere().getCodMat(), h, Double::sum);
        }
        return totals.entrySet().stream()
                .map(e -> Map.<String, Object>of("codMat", e.getKey(), "total", e.getValue()))
                .toList();
    }

    @PostMapping
    public Absence add(@RequestBody Absence a) {
        a.setId(null);
        resolve(a);
        return absenceRepository.save(a);
    }

    @PutMapping("/{id}")
    public Absence update(@PathVariable Long id, @RequestBody Absence a) {
        a.setId(id);
        resolve(a);
        return absenceRepository.save(a);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        absenceRepository.deleteById(id);
    }

    // recharge la matière et l'étudiant depuis la base à partir de leurs ids
    private void resolve(Absence a) {
        a.setMatiere(matiereRepository.findById(a.getMatiere().getCodMat()).orElseThrow());
        a.setEtudiant(etudiantRepository.findById(a.getEtudiant().getId()).orElseThrow());
    }

}