package com.gigmework.backend.repo;

import com.gigmework.backend.domain.Job;
import com.gigmework.backend.domain.JobStatus;
import com.gigmework.backend.domain.UserAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JobRepository extends JpaRepository<Job, Long> {
    // Recent jobs assigned to a freelancer
    List<Job> findTop5ByAssignedFreelancerOrderByCreatedAtDesc(UserAccount freelancer);

    // Open jobs for recommendations (unassigned)
    List<Job> findTop5ByStatusAndAssignedFreelancerIsNullOrderByCreatedAtDesc(JobStatus status);

    long countByAssignedFreelancer(UserAccount freelancer);
}
