package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "portfolio_items")
public class PortfolioItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "freelancer_id")
    private UserAccount freelancer;

    @Column(nullable = false, length = 160)
    private String title;

    @Column(length = 2000)
    private String description;

    @Column(length = 500)
    private String fileUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MediaType mediaType;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected PortfolioItem() {}
    public PortfolioItem(UserAccount freelancer, String title, String description, String fileUrl, MediaType mediaType) {
        this.freelancer = freelancer;
        this.title = title;
        this.description = description;
        this.fileUrl = fileUrl;
        this.mediaType = mediaType;
    }
    public Long getId() { return id; }
    public UserAccount getFreelancer() { return freelancer; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getFileUrl() { return fileUrl; }
    public MediaType getMediaType() { return mediaType; }
    public Instant getCreatedAt() { return createdAt; }
}
