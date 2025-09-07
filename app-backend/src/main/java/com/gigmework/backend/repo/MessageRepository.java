package com.gigmework.backend.repo;

import com.gigmework.backend.domain.Message;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {
    List<Message> findTop100ByConversation_IdOrderByCreatedAtDesc(Long conversationId);
    List<Message> findByConversation_IdAndIdGreaterThanOrderByCreatedAtAsc(Long conversationId, Long afterMessageId);
    long countByConversation_Id(Long conversationId);
}

