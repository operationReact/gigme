package com.gigmework.backend.service;

import com.gigmework.backend.domain.FreelancerProfile;
import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.repo.FreelancerProfileRepository;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional
public class FreelancerProfileService {
    private final FreelancerProfileRepository repo;
    private final UserAccountRepository userRepo;

    public FreelancerProfileService(FreelancerProfileRepository repo, UserAccountRepository userRepo) {
        this.repo = repo; this.userRepo = userRepo;
    }

    public FreelancerProfile createOrUpdate(Long userId, String displayName, String professionalTitle, String bio, String skillsCsv, String imageUrl) {
        UserAccount user = userRepo.findById(userId).orElseThrow(() -> new IllegalArgumentException("user not found"));
        Optional<FreelancerProfile> existing = repo.findByUser(user);
        if (existing.isPresent()) {
            FreelancerProfile fp = existing.get();
            fp.update(displayName, professionalTitle, bio, skillsCsv, imageUrl);
            return fp;
        }
        FreelancerProfile fp = new FreelancerProfile(user, displayName, professionalTitle, bio, skillsCsv, imageUrl);
        return repo.save(fp);
    }

    @Transactional(readOnly = true)
    public Optional<FreelancerProfile> getByUser(Long userId) {
        return userRepo.findById(userId).flatMap(repo::findByUser);
    }
}
