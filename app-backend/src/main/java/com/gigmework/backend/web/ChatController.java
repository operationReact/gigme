package com.gigmework.backend.web;

import com.gigmework.backend.domain.Conversation;
import com.gigmework.backend.domain.Message;
import com.gigmework.backend.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@Validated
public class ChatController {
    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/conversations")
    public ResponseEntity<Map<String, Object>> createConversation(@RequestBody CreateConversationRequest req) {
        Conversation c = chatService.createConversation(req.isGroup(), req.title(), req.participantUserIds());
        return ResponseEntity.ok(Map.of("id", c.getId()));
    }

    @PostMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<Map<String, Object>> sendMessage(@PathVariable Long conversationId,
                                                           @RequestBody SendMessageRequest req) {
        Message m = chatService.sendMessage(conversationId, req.senderUserId(), req.body(), req.attachmentUrl(), req.attachmentMime(), req.kind());
        return ResponseEntity.ok(Map.of("id", m.getId()));
    }

    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<List<MessageDto>> getMessages(@PathVariable Long conversationId,
                                                        @RequestParam(defaultValue = "50") int limit) {
        List<Message> msgs = chatService.getRecentMessages(conversationId, limit);
        return ResponseEntity.ok(msgs.stream().map(MessageDto::from).toList());
    }

    public record CreateConversationRequest(boolean isGroup, String title, List<Long> participantUserIds) {}
    public record SendMessageRequest(Long senderUserId, String body, String attachmentUrl, String attachmentMime, String kind) {}
    public record MessageDto(Long id, Long senderUserId, String body, String attachmentUrl, String attachmentMime, String kind, String createdAt) {
        public static MessageDto from(Message m) {
            return new MessageDto(
                    m.getId(),
                    m.getSender().getId(),
                    m.getBody(),
                    m.getAttachmentUrl(),
                    m.getAttachmentMime(),
                    m.getKind(),
                    m.getCreatedAt().toString()
            );
        }
    }
}

