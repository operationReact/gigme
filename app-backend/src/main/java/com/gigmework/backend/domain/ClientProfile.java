package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "client_profiles")
public class ClientProfile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private UserAccount user;

    @Column(nullable = false, length = 160)
    private String companyName;

    @Column(length = 255)
    private String website;

    @Column(length = 2000)
    private String description;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected ClientProfile() {}

    public ClientProfile(UserAccount user, String companyName, String website, String description) {
        this.user = user;
        this.companyName = companyName;
        this.website = website;
        this.description = description;
    }

    public Long getId() { return id; }
    public UserAccount getUser() { return user; }
    public String getCompanyName() { return companyName; }
    public String getWebsite() { return website; }
    public String getDescription() { return description; }
    public Instant getCreatedAt() { return createdAt; }

    public void update(String companyName, String website, String description) {
        if (companyName != null && !companyName.isBlank()) this.companyName = companyName;
        this.website = website;
        this.description = description;
    }
}

