package com.gigmework.backend.service;

import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.domain.UserRole;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UserService {
    private final UserAccountRepository userRepo;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public UserService(UserAccountRepository userRepo) {
        this.userRepo = userRepo;
    }

    public UserAccount register(String email, String password, UserRole role) {
        if (email == null || email.isBlank()) throw new IllegalArgumentException("email required");
        if (password == null || password.length() < 6) throw new IllegalArgumentException("password too short");
        if (userRepo.existsByEmailIgnoreCase(email)) throw new IllegalStateException("email already used");
        String hash = encoder.encode(password);
        return userRepo.save(new UserAccount(email, hash, role));
    }

    public boolean matches(UserAccount user, String rawPassword){ return encoder.matches(rawPassword, user.getPassword()); }

    @Transactional(readOnly = true)
    public Optional<UserAccount> findByEmail(String email) { return userRepo.findByEmailIgnoreCase(email); }

    @Transactional(readOnly = true)
    public List<UserAccount> findByRole(UserRole role) { return userRepo.findByRole(role); }

    @Transactional(readOnly = true)
    public Optional<UserAccount> findById(Long id) { return userRepo.findById(id); }

    public Optional<UserAccount> authenticate(String email, String rawPassword) {
        if(email==null||rawPassword==null) return Optional.empty();
        return findByEmail(email.toLowerCase()).flatMap(u -> {
            String stored = u.getPassword();
            if(stored == null) return Optional.empty();
            if(stored.startsWith("$2")) { // bcrypt hash
                return matches(u, rawPassword)? Optional.of(u): Optional.empty();
            } else { // legacy plaintext
                if(stored.equals(rawPassword)) {
                    u.setPassword(encoder.encode(rawPassword)); // migrate
                    return Optional.of(u);
                }
                return Optional.empty();
            }
        });
    }
}
