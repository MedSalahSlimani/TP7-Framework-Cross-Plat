package org.isetn.security;

import org.isetn.entities.AppRole;
import org.isetn.entities.AppUser;
import org.isetn.repository.AppUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class AppUserDetailsService implements UserDetailsService {

    @Autowired
    private AppUserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AppUser u = userRepository.findByUsername(username);
        if (u == null) throw new UsernameNotFoundException(username);

        String[] roles = u.getRoles().stream()
                .map(AppRole::getRoleName)
                .toArray(String[]::new);

        return org.springframework.security.core.userdetails.User
                .withUsername(u.getUsername())
                .password(u.getPassword())
                .disabled(!u.isActived())
                .roles(roles) // ajoute le préfixe ROLE_ automatiquement
                .build();
    }
}