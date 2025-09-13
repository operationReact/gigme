package com.gigmework.backend.repo;

import com.gigmework.backend.domain.FreelancerProfile;
import com.gigmework.backend.domain.UserAccount;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FreelancerProfileRepository extends JpaRepository<FreelancerProfile, Long> {
    Optional<FreelancerProfile> findByUser(UserAccount user);

    @Query("""
        SELECT f FROM FreelancerProfile f
        WHERE (
            LOWER(f.displayName) LIKE LOWER(CONCAT(:q, '%')) OR
            LOWER(f.professionalTitle) LIKE LOWER(CONCAT(:q, '%')) OR
            LOWER(f.skillsCsv) LIKE LOWER(CONCAT(:q, '%'))
        )
        ORDER BY f.displayName ASC
        """)
    List<FreelancerProfile> searchPrefix(@Param("q") String q, Pageable pageable);

    @Query("""
        SELECT f FROM FreelancerProfile f
        WHERE f.user.id <> :viewerId AND f.user.id NOT IN (
            SELECT sf.target.id FROM SocialFollow sf WHERE sf.follower.id = :viewerId
        )
        ORDER BY f.id ASC
        """)
    List<FreelancerProfile> suggestions(@Param("viewerId") Long viewerId, Pageable pageable);
}
