package org.isetn.repository;

import org.isetn.entities.Classe;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List; // N'oubliez pas l'import

public interface ClasseRepository extends JpaRepository<Classe, String> {
    // Ajoutez cette ligne :
    List<Classe> findByDepartementCodDept(String codDept);
}