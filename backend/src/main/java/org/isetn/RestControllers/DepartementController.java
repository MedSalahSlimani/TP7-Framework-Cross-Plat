package org.isetn.RestControllers;

import java.util.List;
import org.isetn.entities.Departement;
import org.isetn.repository.DepartementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/departements")
public class DepartementController {
    @Autowired
    private DepartementRepository departementRepository;

    @GetMapping
    public List<Departement> all() {
        return departementRepository.findAll();
    }

    @PostMapping
    public Departement add(@RequestBody Departement d) {
        return departementRepository.save(d);
    }


    @PutMapping("/{id}")
    public Departement update(@PathVariable String id, @RequestBody Departement d) {
        d.setCodDept(id);
        // Ajoutez cette ligne 👇
        return departementRepository.save(d); 
    }
}