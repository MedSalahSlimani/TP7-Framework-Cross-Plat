package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Formation;
import org.isetn.repository.FormationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/formations")
public class FormationController {
    @Autowired
    private FormationRepository formationRepository;

    @GetMapping
    public List<Formation> all() {
        return formationRepository.findAll();
    }

    @PostMapping
    public Formation add(@RequestBody Formation f) {
        return formationRepository.save(f);
    }

    @PutMapping("/{id}")
    public Formation update(@PathVariable Long id, @RequestBody Formation f) {
        f.setId(id);
        return formationRepository.save(f);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        formationRepository.deleteById(id);
    }
}