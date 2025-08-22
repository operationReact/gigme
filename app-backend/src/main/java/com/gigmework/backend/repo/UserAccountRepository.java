package com.gigmework.backend.repo;

import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.domain.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserAccountRepository extends JpaRepository<UserAccount, Long> {
    Optional<UserAccount> findByEmailIgnoreCase(String email);
    List<UserAccount> findByRole(UserRole role);
    boolean existsByEmailIgnoreCase(String email);
}

