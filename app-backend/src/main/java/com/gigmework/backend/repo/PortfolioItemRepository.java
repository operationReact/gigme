package com.gigmework.backend.repo;

import com.gigmework.backend.domain.PortfolioItem;
import com.gigmework.backend.domain.UserAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PortfolioItemRepository extends JpaRepository<PortfolioItem, Long> {
    List<PortfolioItem> findTop6ByFreelancerOrderByCreatedAtDesc(UserAccount freelancer);
    long countByFreelancer(UserAccount freelancer);
}

