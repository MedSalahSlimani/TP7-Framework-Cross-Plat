package org.isetn.repository;

import java.time.LocalDate;
import java.util.List;
import org.isetn.entities.Absence;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AbsenceRepository extends JpaRepository<Absence, Long> {
    List<Absence> findByEtudiantIdOrderByDateADesc(Long etudiantId);

    List<Absence> findByEtudiantId(Long etudiantId);

    void deleteByEtudiantId(Long etudiantId);

    // absences d'une classe, dans une matière, à une date
    List<Absence> findByEtudiantClasseCodClassAndMatiereCodMatAndDateA(
            Integer codClass, String codMat, LocalDate dateA);
}