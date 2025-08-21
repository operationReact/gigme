package com.gigme.app.repository;

import com.gigme.app.model.Gig;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for {@link Gig} entities.
 */
public interface GigRepository extends JpaRepository<Gig, Long> {
}