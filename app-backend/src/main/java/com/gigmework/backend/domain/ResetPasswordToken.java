package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "password_reset_tokens", indexes = @Index(columnList = "token", unique = true))
public class ResetPasswordToken {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    private UserAccount user;

    @Column(nullable = false, unique = true, length = 120)
    private String token;

    @Column(nullable = false)
    private Instant expiresAt;

    private Instant usedAt;

    protected ResetPasswordToken() {}

    private ResetPasswordToken(UserAccount user, String token, Instant expiresAt) {
        this.user = user;
        this.token = token;
        this.expiresAt = expiresAt;
    }

    public static ResetPasswordToken create(UserAccount user, long validMinutes) {
        return new ResetPasswordToken(user, UUID.randomUUID().toString(), Instant.now().plusSeconds(validMinutes * 60));
    }

    public boolean isExpired() { return Instant.now().isAfter(expiresAt); }
    public boolean isUsed() { return usedAt != null; }

    public String getToken() { return token; }
    public UserAccount getUser() { return user; }
    public void markUsed() { this.usedAt = Instant.now(); }
}

