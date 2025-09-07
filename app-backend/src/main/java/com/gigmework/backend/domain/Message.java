package com.gigmework.backend.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "messages")
public class Message {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_user_id", nullable = false)
    private UserAccount sender;

    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(name = "attachment_url", length = 500)
    private String attachmentUrl;

    @Column(name = "attachment_mime", length = 120)
    private String attachmentMime;

    @Column(nullable = false, length = 24)
    private String kind = "text";

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    protected Message() {}

    public Message(Conversation conversation, UserAccount sender, String body) {
        this.conversation = conversation;
        this.sender = sender;
        this.body = body;
    }

    public Long getId() { return id; }
    public Conversation getConversation() { return conversation; }
    public UserAccount getSender() { return sender; }
    public String getBody() { return body; }
    public String getAttachmentUrl() { return attachmentUrl; }
    public String getAttachmentMime() { return attachmentMime; }
    public String getKind() { return kind; }
    public Instant getCreatedAt() { return createdAt; }

    public void setBody(String body) { this.body = body; }
    public void setAttachmentUrl(String attachmentUrl) { this.attachmentUrl = attachmentUrl; }
    public void setAttachmentMime(String attachmentMime) { this.attachmentMime = attachmentMime; }
    public void setKind(String kind) { this.kind = kind; }
}
