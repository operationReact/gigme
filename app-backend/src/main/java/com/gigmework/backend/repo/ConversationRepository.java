package com.gigmework.backend.repo;

import com.gigmework.backend.domain.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {
}

