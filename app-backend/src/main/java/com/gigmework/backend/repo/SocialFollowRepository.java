package com.gigmework.backend.repo;

import com.gigmework.backend.domain.SocialFollow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Collection;
import java.util.List;

public interface SocialFollowRepository extends JpaRepository<SocialFollow, Long> {
    boolean existsByFollowerIdAndTargetId(Long followerId, Long targetId);
    long countByTargetId(Long targetId); // followers count
    long countByFollowerId(Long followerId); // following count
    void deleteByFollowerIdAndTargetId(Long followerId, Long targetId);

    @Query("select sf from SocialFollow sf where sf.follower.id = :followerId and sf.target.id in :targetIds")
    List<SocialFollow> findByFollowerIdAndTargetIdIn(Long followerId, Collection<Long> targetIds);
}

