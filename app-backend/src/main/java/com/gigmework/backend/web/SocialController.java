package com.gigmework.backend.web;

import com.gigmework.backend.service.SocialService;
import com.gigmework.backend.service.SocialService.CreatorSuggestionDto;
import com.gigmework.backend.service.SocialService.SocialCountsDto;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/social")
public class SocialController {
    private final SocialService socialService;
    public SocialController(SocialService socialService) { this.socialService = socialService; }

    @GetMapping("/search")
    public ResponseEntity<List<CreatorSuggestionDto>> search(@RequestParam("q") String q,
                                                             @RequestParam(value = "viewerId", required = false) Long viewerId,
                                                             @RequestParam(value = "limit", required = false, defaultValue = "20") int limit) {
        return ResponseEntity.ok(socialService.search(q, viewerId, limit));
    }

    @GetMapping("/suggestions")
    public ResponseEntity<List<CreatorSuggestionDto>> suggestions(@RequestParam("userId") Long viewerId,
                                                                  @RequestParam(value = "limit", defaultValue = "12") int limit) {
        return ResponseEntity.ok(socialService.suggestions(viewerId, limit));
    }

    @GetMapping("/counts")
    public ResponseEntity<SocialCountsDto> counts(@RequestParam("userId") Long userId) {
        return ResponseEntity.ok(socialService.counts(userId));
    }

    public record FollowRequest(Long targetUserId, Long viewerId) {}

    @PostMapping("/follow")
    public ResponseEntity<?> follow(@RequestBody FollowRequest req) {
        if (req.targetUserId() == null || req.viewerId() == null) return ResponseEntity.badRequest().build();
        socialService.follow(req.viewerId(), req.targetUserId());
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/follow")
    public ResponseEntity<?> unfollow(@RequestParam("targetUserId") Long targetUserId,
                                      @RequestParam("viewerId") Long viewerId) {
        socialService.unfollow(viewerId, targetUserId);
        return ResponseEntity.ok().build();
    }
}

