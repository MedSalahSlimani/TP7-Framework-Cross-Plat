package org.isetn.repository;

import java.util.List;
import org.isetn.entities.Etudiant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface EtudiantRepository extends JpaRepository<Etudiant, Long> {

    List<Etudiant> findByClasseCodClass(String codClass);

    @Query(value = "SELECT CodClass, COUNT(NCE) as count FROM Etudiant GROUP BY CodClass ORDER BY count DESC LIMIT 1", nativeQuery = true)
    Object[] findClasseWithMostStudents();

    long countByClasseCodClass(String codClass);
    void deleteByClasseCodClass(String codClass);

   
    @Query("SELECT e.nom, e.prenom, COALESCE(SUM(a.nha), 0.0) " +
           "FROM Etudiant e " +
           "LEFT JOIN Absence a ON a.etudiant.id = e.id AND a.matiere.codMat = :codMat " +
           "WHERE e.classe.codClass = :codClass " +
           "GROUP BY e.id, e.nom, e.prenom")
    List<Object[]> findAbsencesByClasseAndMatiere(@Param("codClass") String codClass, @Param("codMat") String codMat);
}