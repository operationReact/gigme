package com.gigmework.backend.web;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

@RestController
@RequestMapping("/api/jobs")
public class JobController {

    private final List<Job> jobs = Collections.synchronizedList(new ArrayList<>());
    private final AtomicLong idSequence = new AtomicLong(1);

    @GetMapping
    public List<Job> list() {
        return jobs;
    }

    @PostMapping
    public ResponseEntity<Job> create(@RequestBody JobCreateRequest req) {
        if (req == null || req.title() == null || req.title().isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        Job job = new Job(idSequence.getAndIncrement(), req.title(), req.description());
        jobs.add(job);
        return ResponseEntity.status(HttpStatus.CREATED).body(job);
    }

    public record Job(Long id, String title, String description) {}
    public record JobCreateRequest(String title, String description) {}
}

