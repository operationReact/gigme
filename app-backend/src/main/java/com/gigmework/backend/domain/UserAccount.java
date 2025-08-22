package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "users", uniqueConstraints = @UniqueConstraint(columnNames = "email"))
public class UserAccount {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 160)
    private String email;

    @Column(nullable = false)
    private String password; // (Plain for demo; replace with hashed in real system)

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 24)
    private UserRole role;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
    private FreelancerProfile freelancerProfile;

    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
    private ClientProfile clientProfile;

    protected UserAccount() {}

    public UserAccount(String email, String password, UserRole role) {
        this.email = email.toLowerCase();
        this.password = password;
        this.role = role;
    }

    public Long getId() { return id; }
    public String getEmail() { return email; }
    public String getPassword() { return password; }
    public UserRole getRole() { return role; }
    public Instant getCreatedAt() { return createdAt; }
    public boolean hasFreelancerProfile() { return freelancerProfile != null; }
    public boolean hasClientProfile() { return clientProfile != null; }
    public FreelancerProfile getFreelancerProfile() { return freelancerProfile; }
    public ClientProfile getClientProfile() { return clientProfile; }
    public void setPassword(String password) { this.password = password; }
}
