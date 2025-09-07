package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "conversations")
public class Conversation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "is_group", nullable = false)
    private boolean group;

    @Column
    private String title;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @OneToMany(mappedBy = "conversation", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ConversationParticipant> participants = new HashSet<>();

    @OneToMany(mappedBy = "conversation", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("createdAt ASC")
    private List<Message> messages = new ArrayList<>();

    protected Conversation() {}

    public Conversation(boolean group, String title) {
        this.group = group;
        this.title = title;
    }

    public Long getId() { return id; }
    public boolean isGroup() { return group; }
    public String getTitle() { return title; }
    public Instant getCreatedAt() { return createdAt; }
    public Set<ConversationParticipant> getParticipants() { return participants; }
    public List<Message> getMessages() { return messages; }

    public void setGroup(boolean group) { this.group = group; }
    public void setTitle(String title) { this.title = title; }
}

