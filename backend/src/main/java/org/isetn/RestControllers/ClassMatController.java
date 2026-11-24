


package org.isetn.RestControllers;

import org.isetn.entities.Classe;
import org.isetn.entities.ClassMat;
import org.isetn.repository.ClasseRepository;
import org.isetn.repository.ClassMatRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/classmat")
public class ClassMatController {

    @Autowired
    private ClassMatRepository classMatRepository;
    
    @Autowired
    private ClasseRepository classeRepository;

    // 🔴 REGARDEZ BIEN ICI : codClass doit être un String
    @PostMapping("/{codClass}/{codMat}")
    public ClassMat createOrUpdate(
            @PathVariable String codClass, // <--- String et non Integer
            @PathVariable String codMat,   // <--- String
            @RequestBody ClassMat cm) {
        
        // 1. Récupération de la classe (findById attend un String)
        Classe classe = classeRepository.findById(codClass)
                .orElseThrow(() -> new RuntimeException("Classe introuvable : " + codClass));
        
        // 2. Affectation
        cm.setClasse(classe); 
        
        // 3. Sauvegarde
        return classMatRepository.save(cm);
    }
}





