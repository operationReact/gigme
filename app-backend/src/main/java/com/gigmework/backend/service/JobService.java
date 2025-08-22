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
}

