package com.gigmework.backend.service;

import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.domain.UserRole;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UserService {
    private final UserAccountRepository userRepo;

    public UserService(UserAccountRepository userRepo) {
        this.userRepo = userRepo;
    }

    public UserAccount register(String email, String password, UserRole role) {
        if (email == null || email.isBlank()) throw new IllegalArgumentException("email required");
        if (password == null || password.length() < 4) throw new IllegalArgumentException("password too short");
        if (userRepo.existsByEmailIgnoreCase(email)) throw new IllegalStateException("email already used");
        return userRepo.save(new UserAccount(email, password, role));
    }

    @Transactional(readOnly = true)
    public Optional<UserAccount> findByEmail(String email) { return userRepo.findByEmailIgnoreCase(email); }

    @Transactional(readOnly = true)
    public List<UserAccount> findByRole(UserRole role) { return userRepo.findByRole(role); }

    @Transactional(readOnly = true)
    public Optional<UserAccount> findById(Long id) { return userRepo.findById(id); }
}

