package com.gigmework.backend.web;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.service.PostService;
import com.gigmework.backend.service.PostService.MediaSpec;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/feed")
public class FeedController {
    private final PostService postService;

    public FeedController(PostService postService) { this.postService = postService; }

    @PostMapping("/posts")
    public ResponseEntity<PostDto> create(@RequestBody CreatePostRequest req) {
        List<MediaSpec> specs = req.media() == null ? List.of() : req.media().stream()
                .map(m -> new MediaSpec(m.url(), m.mediaType(), m.width(), m.height(), m.durationSeconds(), m.thumbnailUrl()))
                .toList();
        Post p = postService.createPost(req.authorId(), req.content(), specs);
        return ResponseEntity.ok(toDto(p, req.authorId()));
    }

    @GetMapping("/posts")
    public ResponseEntity<Page<PostDto>> list(@RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "10") int size,
                                              @RequestParam(required = false) Long viewerId) {
        Page<Post> pg = postService.list(page, size);
        Page<PostDto> mapped = pg.map(p -> toDto(p, viewerId));
        return ResponseEntity.ok(mapped);
    }

    @PostMapping("/posts/{id}/like")
    public ResponseEntity<?> like(@PathVariable Long id, @RequestParam Long userId) {
        postService.like(id, userId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/posts/{id}/like")
    public ResponseEntity<?> unlike(@PathVariable Long id, @RequestParam Long userId) {
        postService.unlike(id, userId);
        return ResponseEntity.ok().build();
    }

    private PostDto toDto(Post p, Long viewerId) {
        List<PostMediaDto> media = p.getMedia().stream().map(m -> new PostMediaDto(
                m.getId(), m.getUrl(), m.getMediaType(), m.getWidth(), m.getHeight(), m.getDurationSeconds(), m.getThumbnailUrl(), m.getOrderIndex()
        )).collect(Collectors.toList());
        long likeCount = postService.likeCount(p.getId());
        boolean likedByMe = viewerId != null && postService.likedBy(p.getId(), viewerId);
        return new PostDto(p.getId(), p.getAuthor().getId(), p.getAuthor().getEmail(), p.getContent(), p.getCreatedAt(), likeCount, 0, likedByMe, media);
    }

    public record CreatePostRequest(Long authorId, String content, List<CreateMediaItem> media) {}
    public record CreateMediaItem(String url, MediaType mediaType, Integer width, Integer height, Integer durationSeconds, String thumbnailUrl) {}

    public record PostDto(Long id, Long authorId, String authorName, String content, Instant createdAt, long likeCount, long commentCount, boolean likedByMe, List<PostMediaDto> media) {}
    public record PostMediaDto(Long id, String url, MediaType mediaType, Integer width, Integer height, Integer durationSeconds, String thumbnailUrl, int orderIndex) {}
}

