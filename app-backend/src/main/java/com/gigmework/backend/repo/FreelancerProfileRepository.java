package com.gigmework.backend.repo;

import com.gigmework.backend.domain.FreelancerProfile;
import com.gigmework.backend.domain.UserAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FreelancerProfileRepository extends JpaRepository<FreelancerProfile, Long> {
    Optional<FreelancerProfile> findByUser(UserAccount user);
}

