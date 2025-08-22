package com.gigmework.backend.repo;

import com.gigmework.backend.domain.ClientProfile;
import com.gigmework.backend.domain.UserAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ClientProfileRepository extends JpaRepository<ClientProfile, Long> {
    Optional<ClientProfile> findByUser(UserAccount user);
}

