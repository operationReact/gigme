package com.gigmework.backend.service;

import com.gigmework.backend.domain.Job;
import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.domain.UserRole;
import com.gigmework.backend.repo.JobRepository;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class JobService {
    private final JobRepository jobRepo;
    private final UserAccountRepository userRepo;

    public JobService(JobRepository jobRepo, UserAccountRepository userRepo) {
        this.jobRepo = jobRepo;
        this.userRepo = userRepo;
    }

    @Transactional(readOnly = true)
    public List<Job> listJobs() {
        return jobRepo.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
    }

    public Job createJob(String title, String description) {
        if (title == null || title.isBlank()) throw new IllegalArgumentException("title required");
        // pick any client user as owner (dev simplification)
        Optional<UserAccount> owner = userRepo.findByRole(UserRole.CLIENT).stream().findFirst();
        Job job = new Job(title.trim(), description, owner.orElse(null));
        return jobRepo.save(job);
    }

    @Transactional(readOnly = true)
    public long countNewJobs() {
        return jobRepo.countByAssignedFreelancerIsNullAndStatus(com.gigmework.backend.domain.JobStatus.OPEN);
    }

    // List all open jobs (unassigned)
    @Transactional(readOnly = true)
    public List<Job> listOpenJobs() {
        return jobRepo.findByStatusAndAssignedFreelancerIsNull(com.gigmework.backend.domain.JobStatus.OPEN);
    }

    // Apply for a job: assign the given freelancer and set status to ASSIGNED
    public Job applyForJob(Long jobId, UserAccount freelancer) {
        Job job = jobRepo.findById(jobId).orElseThrow(() -> new IllegalArgumentException("Job not found"));
        if (job.getStatus() != com.gigmework.backend.domain.JobStatus.OPEN || job.getAssignedFreelancer() != null) {
            throw new IllegalStateException("Job is not open for application");
        }
        job.assignFreelancer(freelancer);
        return jobRepo.save(job);
    }

    // Find user by email
    public UserAccount findUserByEmail(String email) {
        return userRepo.findByEmailIgnoreCase(email).orElse(null);
    }
}
