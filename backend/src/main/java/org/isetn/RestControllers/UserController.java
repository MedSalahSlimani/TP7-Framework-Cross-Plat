package org.isetn.RestControllers;

import org.isetn.entities.AppUser;
import org.isetn.repository.AppUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@CrossOrigin("*")
public class UserController {

    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> payload) {
        // On récupère l'identifiant qu'il s'appelle "email" ou "username" dans le JSON
        String loginIdentifier = payload.get("email") != null ? payload.get("email") : payload.get("username");
        String password = payload.get("password");

        // On cherche l'utilisateur par son username (qui contient l'email)
        AppUser oldUser = userRepository.findByUsername(loginIdentifier);

        // On vérifie le mot de passe
        if (oldUser != null && passwordEncoder.matches(password, oldUser.getPassword())) {
            return ResponseEntity.ok(oldUser); // Succès (Code 200)
        }

        // Échec
        return ResponseEntity.status(401).body("Email ou mot de passe incorrect");
    }
}