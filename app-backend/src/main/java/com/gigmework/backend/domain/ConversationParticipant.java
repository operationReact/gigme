package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "conversation_participants")
public class ConversationParticipant {
    @EmbeddedId
    private ConversationParticipantId id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("conversationId")
    @JoinColumn(name = "conversation_id")
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private UserAccount user;

    @Column(nullable = false, length = 24)
    private String role = "member";

    @Column(name = "last_read_msg_id")
    private Long lastReadMsgId;

    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt = Instant.now();

    protected ConversationParticipant() {}

    public ConversationParticipant(Conversation conversation, UserAccount user, String role) {
        this.conversation = conversation;
        this.user = user;
        this.role = role == null ? "member" : role;
        this.id = new ConversationParticipantId(
                conversation != null ? conversation.getId() : null,
                user != null ? user.getId() : null
        );
    }

    public ConversationParticipantId getId() { return id; }
    public Conversation getConversation() { return conversation; }
    public UserAccount getUser() { return user; }
    public String getRole() { return role; }
    public Long getLastReadMsgId() { return lastReadMsgId; }
    public Instant getJoinedAt() { return joinedAt; }

    public void setRole(String role) { this.role = role; }
    public void setLastReadMsgId(Long lastReadMsgId) { this.lastReadMsgId = lastReadMsgId; }
}

