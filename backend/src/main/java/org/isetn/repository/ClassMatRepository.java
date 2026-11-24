package org.isetn.repository;

import org.isetn.entities.ClassMat;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClassMatRepository extends JpaRepository<ClassMat, Long> {
    
    // La méthode doit renvoyer un seul objet ClassMat
    ClassMat findByClasseCodClassAndMatiereCodMat(String codClass, String codMat);
    
    void deleteByClasseCodClass(String codClass);
}
