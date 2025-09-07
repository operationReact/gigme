package com.gigmework.backend.service;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.repo.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ChatService {
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository participantRepository;
    private final MessageRepository messageRepository;
    private final UserAccountRepository userAccountRepository;

    public ChatService(ConversationRepository conversationRepository,
                       ConversationParticipantRepository participantRepository,
                       MessageRepository messageRepository,
                       UserAccountRepository userAccountRepository) {
        this.conversationRepository = conversationRepository;
        this.participantRepository = participantRepository;
        this.messageRepository = messageRepository;
        this.userAccountRepository = userAccountRepository;
    }

    @Transactional
    public Conversation createConversation(boolean isGroup, String title, List<Long> participantUserIds) {
        Conversation conv = new Conversation(isGroup, title);
        conv = conversationRepository.save(conv);
        if (participantUserIds != null) {
            for (Long uid : participantUserIds) {
                addParticipant(conv.getId(), uid, "member");
            }
        }
        return conv;
    }

    @Transactional
    public ConversationParticipant addParticipant(Long conversationId, Long userId, String role) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found: " + conversationId));
        UserAccount user = userAccountRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        if (participantRepository.existsByConversation_IdAndUser_Id(conversationId, userId)) {
            return participantRepository.findById(new ConversationParticipantId(conversationId, userId))
                    .orElseThrow();
        }
        ConversationParticipant cp = new ConversationParticipant(conv, user, role);
        return participantRepository.save(cp);
    }

    @Transactional
    public Message sendMessage(Long conversationId, Long senderUserId, String body,
                               String attachmentUrl, String attachmentMime, String kind) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found: " + conversationId));
        UserAccount sender = userAccountRepository.findById(senderUserId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + senderUserId));
        if (!participantRepository.existsByConversation_IdAndUser_Id(conversationId, senderUserId)) {
            throw new IllegalStateException("Sender is not a participant in the conversation");
        }
        Message msg = new Message(conv, sender, body);
        msg.setAttachmentUrl(attachmentUrl);
        msg.setAttachmentMime(attachmentMime);
        if (kind != null && !kind.isBlank()) msg.setKind(kind);
        return messageRepository.save(msg);
    }

    @Transactional(readOnly = true)
    public List<Message> getRecentMessages(Long conversationId, int limit) {
        List<Message> msgs = messageRepository.findTop100ByConversation_IdOrderByCreatedAtDesc(conversationId);
        if (limit > 0 && msgs.size() > limit) {
            return msgs.subList(0, limit);
        }
        return msgs;
    }
}

