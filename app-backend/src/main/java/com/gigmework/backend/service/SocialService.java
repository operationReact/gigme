package com.gigmework.backend.service;

import com.gigmework.backend.domain.FreelancerProfile;
import com.gigmework.backend.domain.SocialFollow;
import com.gigmework.backend.domain.UserAccount;
import com.gigmework.backend.repo.FreelancerProfileRepository;
import com.gigmework.backend.repo.PostRepository;
import com.gigmework.backend.repo.SocialFollowRepository;
import com.gigmework.backend.repo.UserAccountRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class SocialService {
    private final FreelancerProfileRepository freelancerRepo;
    private final SocialFollowRepository followRepo;
    private final UserAccountRepository userRepo;
    private final PostRepository postRepo;

    public SocialService(FreelancerProfileRepository freelancerRepo,
                         SocialFollowRepository followRepo,
                         UserAccountRepository userRepo,
                         PostRepository postRepo) {
        this.freelancerRepo = freelancerRepo;
        this.followRepo = followRepo;
        this.userRepo = userRepo;
        this.postRepo = postRepo;
    }

    public List<CreatorSuggestionDto> search(String q, Long viewerId, int limit) {
        String query = normalize(q);
        if (query.isEmpty()) return List.of();
        List<FreelancerProfile> results = freelancerRepo.searchPrefix(query, PageRequest.of(0, Math.min(limit, 50)));
        return mapWithFollow(results, viewerId);
    }

    public List<CreatorSuggestionDto> suggestions(Long viewerId, int limit) {
        List<FreelancerProfile> list = freelancerRepo.suggestions(viewerId, PageRequest.of(0, Math.min(limit, 30)));
        return mapWithFollow(list, viewerId);
    }

    private List<CreatorSuggestionDto> mapWithFollow(List<FreelancerProfile> profiles, Long viewerId){
        if (profiles.isEmpty()) return List.of();
        List<Long> ids = profiles.stream().map(p -> p.getUser().getId()).toList();
        Set<Long> following = viewerId == null ? Set.of() : followRepo.findByFollowerIdAndTargetIdIn(viewerId, ids)
                .stream().map(f -> f.getTarget().getId()).collect(Collectors.toSet());
        return profiles.stream().map(p -> new CreatorSuggestionDto(
                p.getUser().getId(),
                p.getDisplayName(),
                Optional.ofNullable(p.getProfessionalTitle()).orElse(""),
                p.getImageUrl(),
                following.contains(p.getUser().getId())
        )).toList();
    }

    @Transactional
    public void follow(Long followerId, Long targetId) {
        if (Objects.equals(followerId, targetId)) return;
        if (followRepo.existsByFollowerIdAndTargetId(followerId, targetId)) return;
        UserAccount follower = userRepo.findById(followerId).orElseThrow();
        UserAccount target = userRepo.findById(targetId).orElseThrow();
        followRepo.save(new SocialFollow(follower, target));
    }

    @Transactional
    public void unfollow(Long followerId, Long targetId) {
        followRepo.deleteByFollowerIdAndTargetId(followerId, targetId);
    }

    public SocialCountsDto counts(Long userId) {
        long posts = postRepo.countByAuthorId(userId);
        long followers = followRepo.countByTargetId(userId);
        long following = followRepo.countByFollowerId(userId);
        return new SocialCountsDto(posts, followers, following);
    }

    private String normalize(String s){
        if (s == null) return "";
        s = s.trim();
        if (s.startsWith("@")) s = s.substring(1);
        return s.toLowerCase(Locale.ROOT);
    }

    // DTOs
    public record CreatorSuggestionDto(Long userId, String name, String title, String avatarUrl, boolean followedByMe){}
    public record SocialCountsDto(long posts, long followers, long following){}
}
