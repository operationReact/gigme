package com.gigmework.backend.repo;

import com.gigmework.backend.domain.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<Post, Long> {
    @EntityGraph(attributePaths = {"author", "media"})
    Page<Post> findAllByOrderByCreatedAtDesc(Pageable pageable);

    long countByAuthorId(Long authorId);
}
