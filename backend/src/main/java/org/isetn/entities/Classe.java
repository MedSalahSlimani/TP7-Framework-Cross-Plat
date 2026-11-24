package org.isetn.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Transient;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Classe {
    @Id
    private String codClass;

    private String nomClass;

    @ManyToOne
    private Departement departement;

    // colonne NbrEtud de la table Classe (mise à jour par le bouton de l'examen)
    private Integer nbrEtud;

    // calculé à la volée pour les autres écrans (pas stocké en base)
    @Transient
    private Integer nbreEtud;

    public Classe(String codClass, String nomClass, Departement departement, Integer nbreEtud) {
        this.codClass = codClass;
        this.nomClass = nomClass;
        this.departement = departement;
        this.nbreEtud = nbreEtud;
    }
}



