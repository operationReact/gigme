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

    public FreelancerProfile createOrUpdate(Long userId,
                                            String displayName,
                                            String professionalTitle,
                                            String bio,
                                            String skillsCsv,
                                            String imageUrl,
                                            String location,
                                            String contactEmail,
                                            String phone,
                                            String website,
                                            String linkedin,
                                            String github,
                                            Integer hourlyRateCents,
                                            String currency,
                                            Boolean available,
                                            String extraJson,
                                            String socialLinksJson) {
        UserAccount user = userRepo.findById(userId).orElseThrow(() -> new IllegalArgumentException("user not found"));
        // basic validation and normalization
        String name = displayName == null ? null : displayName.trim();
        if (name == null || name.isEmpty()) throw new IllegalArgumentException("displayName is required");

        Optional<FreelancerProfile> existing = repo.findByUser(user);
        if (existing.isPresent()) {
            FreelancerProfile fp = existing.get();
            fp.update(name, professionalTitle, bio, skillsCsv, imageUrl,
                    location, contactEmail, phone, website, linkedin, github,
                    hourlyRateCents, currency, available);
            // set extensible json fields if provided
            if (extraJson != null && !extraJson.isBlank()) fp.setExtraJson(extraJson);
            if (socialLinksJson != null && !socialLinksJson.isBlank()) fp.setSocialLinksJson(socialLinksJson);
            return fp;
        }
        FreelancerProfile fp = new FreelancerProfile(user, name, professionalTitle, bio, skillsCsv, imageUrl,
                location, contactEmail, phone, website, linkedin, github, hourlyRateCents, currency, available);
        if (extraJson != null && !extraJson.isBlank()) fp.setExtraJson(extraJson);
        if (socialLinksJson != null && !socialLinksJson.isBlank()) fp.setSocialLinksJson(socialLinksJson);
        return repo.save(fp);
    }

    @Transactional(readOnly = true)
    public Optional<FreelancerProfile> getByUser(Long userId) {
        return userRepo.findById(userId).flatMap(repo::findByUser);
    }
}
