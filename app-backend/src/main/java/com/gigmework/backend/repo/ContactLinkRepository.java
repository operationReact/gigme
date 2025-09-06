package com.gigmework.backend.repo;

import com.gigmework.backend.models.ContactLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContactLinkRepository extends JpaRepository<ContactLink, Long> {
    List<ContactLink> findByUserId(Long userId);
}
