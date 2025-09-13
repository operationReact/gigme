package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "social_follow", uniqueConstraints = @UniqueConstraint(columnNames = {"follower_id","target_id"}))
public class SocialFollow {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "follower_id", nullable = false)
    private UserAccount follower;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "target_id", nullable = false)
    private UserAccount target;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected SocialFollow() {}
    public SocialFollow(UserAccount follower, UserAccount target) {
        this.follower = follower; this.target = target;
    }

    public Long getId() { return id; }
    public UserAccount getFollower() { return follower; }
    public UserAccount getTarget() { return target; }
    public Instant getCreatedAt() { return createdAt; }
}

