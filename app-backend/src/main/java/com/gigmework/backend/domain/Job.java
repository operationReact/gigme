package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "jobs")
public class Job {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 4000)
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "client_id")
    private UserAccount clientOwner; // the client who posted

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "freelancer_id")
    private UserAccount assignedFreelancer; // optional

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected Job() {}

    public Job(String title, String description, UserAccount clientOwner) {
        this.title = title;
        this.description = description;
        this.clientOwner = clientOwner;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public UserAccount getClientOwner() { return clientOwner; }
    public UserAccount getAssignedFreelancer() { return assignedFreelancer; }
    public Instant getCreatedAt() { return createdAt; }

    public void assignFreelancer(UserAccount freelancer) { this.assignedFreelancer = freelancer; }
}

