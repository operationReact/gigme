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

    // New optional contact and profile fields
    @Column(length = 160)
    private String location;

    @Column(length = 160)
    private String contactEmail;

    @Column(length = 40)
    private String phone;

    @Column(length = 300)
    private String website;

    @Column(length = 300)
    private String linkedin;

    @Column(length = 300)
    private String github;

    private Integer hourlyRateCents; // store minor units

    @Column(length = 8)
    private String currency; // ISO code e.g. USD

    private Boolean available;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected FreelancerProfile() {}

    public FreelancerProfile(UserAccount user,
                             String displayName,
                             String professionalTitle,
                             String bio,
                             String skillsCsv,
                             String imageUrl,
                             String location,
                             String contactEmail,
                             String phone,
                             String website,
                             String linkedin,
                             String github,
                             Integer hourlyRateCents,
                             String currency,
                             Boolean available) {
        this.user = user;
        this.displayName = displayName;
        this.professionalTitle = professionalTitle;
        this.bio = bio;
        this.skillsCsv = skillsCsv;
        this.imageUrl = imageUrl;
        this.location = location;
        this.contactEmail = contactEmail;
        this.phone = phone;
        this.website = website;
        this.linkedin = linkedin;
        this.github = github;
        this.hourlyRateCents = hourlyRateCents;
        this.currency = currency;
        this.available = available;
    }

    public Long getId() { return id; }
    public UserAccount getUser() { return user; }
    public String getDisplayName() { return displayName; }
    public String getProfessionalTitle() { return professionalTitle; }
    public String getBio() { return bio; }
    public String getSkillsCsv() { return skillsCsv; }
    public String getImageUrl() { return imageUrl; }
    public String getLocation() { return location; }
    public String getContactEmail() { return contactEmail; }
    public String getPhone() { return phone; }
    public String getWebsite() { return website; }
    public String getLinkedin() { return linkedin; }
    public String getGithub() { return github; }
    public Integer getHourlyRateCents() { return hourlyRateCents; }
    public String getCurrency() { return currency; }
    public Boolean getAvailable() { return available; }
    public Instant getCreatedAt() { return createdAt; }

    public void update(String displayName,
                       String professionalTitle,
                       String bio,
                       String skillsCsv,
                       String imageUrl,
                       String location,
                       String contactEmail,
                       String phone,
                       String website,
                       String linkedin,
                       String github,
                       Integer hourlyRateCents,
                       String currency,
                       Boolean available) {
        this.displayName = displayName;
        this.professionalTitle = professionalTitle;
        this.bio = bio;
        this.skillsCsv = skillsCsv;
        this.imageUrl = imageUrl;
        this.location = location;
        this.contactEmail = contactEmail;
        this.phone = phone;
        this.website = website;
        this.linkedin = linkedin;
        this.github = github;
        this.hourlyRateCents = hourlyRateCents;
        this.currency = currency;
        this.available = available;
    }
}
