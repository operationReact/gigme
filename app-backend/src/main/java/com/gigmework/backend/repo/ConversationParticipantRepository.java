package com.gigmework.backend.repo;

import com.gigmework.backend.domain.ConversationParticipant;
import com.gigmework.backend.domain.ConversationParticipantId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ConversationParticipantRepository extends JpaRepository<ConversationParticipant, ConversationParticipantId> {
    List<ConversationParticipant> findByConversation_Id(Long conversationId);
    List<ConversationParticipant> findByUser_Id(Long userId);
    boolean existsByConversation_IdAndUser_Id(Long conversationId, Long userId);
}

