package com.gigmework.backend.service;

import com.gigmework.backend.domain.ClientProfile;
import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.repo.ClientProfileRepository;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional
public class ClientProfileService {
    private final ClientProfileRepository repo;
    private final UserAccountRepository userRepo;

    public ClientProfileService(ClientProfileRepository repo, UserAccountRepository userRepo) {
        this.repo = repo; this.userRepo = userRepo;
    }

    public ClientProfile createOrUpdate(Long userId, String companyName, String website, String description) {
        UserAccount user = userRepo.findById(userId).orElseThrow(() -> new IllegalArgumentException("user not found"));
        Optional<ClientProfile> existing = repo.findByUser(user);
        if (existing.isPresent()) {
            ClientProfile cp = existing.get();
            cp.update(companyName, website, description);
            return cp;
        }
        ClientProfile cp = new ClientProfile(user, companyName, website, description);
        return repo.save(cp);
    }

    @Transactional(readOnly = true)
    public Optional<ClientProfile> getByUser(Long userId) {
        return userRepo.findById(userId).flatMap(repo::findByUser);
    }
}

