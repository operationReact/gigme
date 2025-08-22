package com.gigmework.backend.repo;

import com.gigmework.backend.domain.ResetPasswordToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Optional;

public interface ResetPasswordTokenRepository extends JpaRepository<ResetPasswordToken, Long> {
    Optional<ResetPasswordToken> findByToken(String token);
    long deleteByExpiresAtBefore(Instant instant);
}

