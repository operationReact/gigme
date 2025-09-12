package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "post_likes", uniqueConstraints = @UniqueConstraint(columnNames = {"post_id","user_id"}))
public class PostLike {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id")
    private Post post;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private UserAccount user;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected PostLike() {}
    public PostLike(Post post, UserAccount user){ this.post = post; this.user = user; }
    public Long getId(){ return id; }
    public Post getPost(){ return post; }
    public UserAccount getUser(){ return user; }
    public Instant getCreatedAt(){ return createdAt; }
}

