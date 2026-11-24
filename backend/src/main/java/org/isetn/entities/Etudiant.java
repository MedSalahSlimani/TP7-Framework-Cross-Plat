package org.isetn.entities;

import java.time.LocalDate;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Etudiant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    
    private Long id;

    @Column(unique = true, length = 20)
    private String nce; // numéro de carte étudiant, ex: E1

    private String nom;
    private String prenom;
    private LocalDate dateNais;
    private String lieuNais;

    @ManyToOne
    @JoinColumn(name = "cod_class") 
    private Classe classe;

    @ManyToOne
    private Formation formation;


  
}