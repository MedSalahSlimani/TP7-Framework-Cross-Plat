package org.isetn.RestControllers;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.isetn.entities.Classe;
import org.isetn.repository.ClasseRepository;
import org.isetn.repository.EtudiantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/exam")
public class ExamenController {

    
    @Autowired
    private EtudiantRepository etudiantRepository;

    @Autowired
    private ClasseRepository classeRepository;
   

    @GetMapping("/absences/{codClass}/{codMat}")
    public List<Map<String, Object>> getAbsencesByClasseAndMatiere(
            @PathVariable String codClass, 
            @PathVariable String codMat) {
        
        List<Object[]> results = etudiantRepository.findAbsencesByClasseAndMatiere(codClass, codMat);
        List<Map<String, Object>> response = new ArrayList<>();
        
        for (Object[] row : results) {
            Map<String, Object> map = new HashMap<>();
            map.put("nom", row[0]);
            map.put("prenom", row[1]);
            map.put("nha", row[2]);
            response.add(map);
        }
        return response;
    }

    @GetMapping("/top-classe")
    public Map<String, Object> getTopClasse() {
        Object[] result = etudiantRepository.findClasseWithMostStudents();
        Map<String, Object> response = new HashMap<>();
        if (result != null) {
            response.put("codClass", result[0]);
            response.put("count", result[1]);
        }
        return response;
    }

    @PutMapping("/update-nbr-etud/{codClass}/{count}")
    public String updateNbrEtud(@PathVariable String codClass, @PathVariable int count) {
        
        Classe classe = classeRepository.findById(codClass).orElse(null);
        if (classe != null) {
            classe.setNbrEtud(count);
            classeRepository.save(classe);
            return "Mise à jour réussie";
        }
        return "Classe non trouvée";
    }
}


