package com.gigmework.backend.service;

import com.gigmework.backend.domain.*;
import com.gigmework.backend.repo.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PostService {
    private final PostRepository postRepository;
    private final PostMediaRepository postMediaRepository;
    private final PostLikeRepository postLikeRepository;
    private final UserAccountRepository userAccountRepository;

    public PostService(PostRepository postRepository, PostMediaRepository postMediaRepository, PostLikeRepository postLikeRepository, UserAccountRepository userAccountRepository) {
        this.postRepository = postRepository;
        this.postMediaRepository = postMediaRepository;
        this.postLikeRepository = postLikeRepository;
        this.userAccountRepository = userAccountRepository;
    }

    @Transactional
    public Post createPost(Long authorId, String content, List<MediaSpec> mediaSpecs) {
        UserAccount author = userAccountRepository.findById(authorId).orElseThrow();
        Post post = new Post(author, content == null ? "" : content.trim());
        post = postRepository.save(post);
        int idx = 0;
        for (MediaSpec spec : mediaSpecs) {
            PostMedia pm = new PostMedia(post, spec.url(), spec.mediaType(), idx++, spec.width(), spec.height(), spec.durationSeconds(), spec.thumbnailUrl());
            post.getMedia().add(pm);
        }
        return postRepository.save(post); // cascade persists media
    }

    public record MediaSpec(String url, MediaType mediaType, Integer width, Integer height, Integer durationSeconds, String thumbnailUrl) {}

    public Page<Post> list(int page, int size) {
        return postRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(page, size));
    }

    public long likeCount(Long postId) { return postLikeRepository.countByPostId(postId); }
    public boolean likedBy(Long postId, Long userId) { return userId != null && postLikeRepository.existsByPostIdAndUserId(postId, userId); }

    @Transactional
    public void like(Long postId, Long userId) {
        if (postLikeRepository.existsByPostIdAndUserId(postId, userId)) return;
        Post post = postRepository.findById(postId).orElseThrow();
        UserAccount user = userAccountRepository.findById(userId).orElseThrow();
        postLikeRepository.save(new PostLike(post, user));
    }

    @Transactional
    public void unlike(Long postId, Long userId) {
        postLikeRepository.deleteByPostIdAndUserId(postId, userId);
    }
}

