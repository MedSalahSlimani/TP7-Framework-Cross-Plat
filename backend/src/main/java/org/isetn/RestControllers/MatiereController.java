package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Matiere;
import org.isetn.repository.MatiereRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/matieres")
public class MatiereController {
    @Autowired
    private MatiereRepository matiereRepository;

    @GetMapping
    public List<Matiere> all() {
        return matiereRepository.findAll();
    }

    @PostMapping
    public Matiere add(@RequestBody Matiere m) {
        return matiereRepository.save(m);
    }

    @PutMapping("/{codMat}")
    public Matiere update(@PathVariable String codMat, @RequestBody Matiere m) {
        m.setCodMat(codMat);
        return matiereRepository.save(m);
    }

    @DeleteMapping("/{codMat}")
    public void delete(@PathVariable String codMat) {
        matiereRepository.deleteById(codMat);
    }
}