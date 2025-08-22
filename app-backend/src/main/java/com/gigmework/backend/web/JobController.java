package com.gigmework.backend.web;

import com.gigmework.backend.domain.Job;
import com.gigmework.backend.service.JobService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/jobs")
public class JobController {

    private final JobService jobService;

    public JobController(JobService jobService) {
        this.jobService = jobService;
    }

    @GetMapping
    public List<JobDto> list() {
        return jobService.listJobs().stream().map(JobDto::from).collect(Collectors.toList());
    }

    @PostMapping
    public ResponseEntity<JobDto> create(@RequestBody JobCreateRequest req) {
        if (req == null || req.title() == null || req.title().isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        Job job = jobService.createJob(req.title(), req.description());
        return ResponseEntity.status(HttpStatus.CREATED).body(JobDto.from(job));
    }

    public record JobCreateRequest(String title, String description) {}

    public record JobDto(Long id, String title, String description, String clientOwnerEmail) {
        public static JobDto from(Job j) {
            return new JobDto(j.getId(), j.getTitle(), j.getDescription(), j.getClientOwner() != null ? j.getClientOwner().getEmail() : null);
        }
    }
}
