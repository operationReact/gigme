package com.gigmework.backend.repo;

import com.gigmework.backend.domain.Job;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JobRepository extends JpaRepository<Job, Long> {
}

