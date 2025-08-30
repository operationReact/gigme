package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "freelancer_profiles")
public class FreelancerProfile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private UserAccount user;

    @Column(nullable = false, length = 120)
    private String displayName;

    @Column(length = 160)
    private String professionalTitle;

    @Column(length = 2000)
    private String bio;

    @Column(length = 1000)
    private String skillsCsv; // comma separated list

    @Column(length = 500)
    private String imageUrl;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected FreelancerProfile() {}

    public FreelancerProfile(UserAccount user, String displayName, String professionalTitle, String bio, String skillsCsv, String imageUrl) {
        this.user = user;
        this.displayName = displayName;
        this.professionalTitle = professionalTitle;
        this.bio = bio;
        this.skillsCsv = skillsCsv;
        this.imageUrl = imageUrl;
    }

    public Long getId() { return id; }
    public UserAccount getUser() { return user; }
    public String getDisplayName() { return displayName; }
    public String getProfessionalTitle() { return professionalTitle; }
    public String getBio() { return bio; }
    public String getSkillsCsv() { return skillsCsv; }
    public String getImageUrl() { return imageUrl; }
    public Instant getCreatedAt() { return createdAt; }

    public void update(String displayName, String professionalTitle, String bio, String skillsCsv, String imageUrl) {
        this.displayName = displayName;
        this.professionalTitle = professionalTitle;
        this.bio = bio;
        this.skillsCsv = skillsCsv;
        this.imageUrl = imageUrl;
    }
}
