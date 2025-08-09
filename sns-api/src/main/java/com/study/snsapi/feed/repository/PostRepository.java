package com.study.snsapi.feed.repository;

import com.study.snsapi.feed.domain.Post;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {
    List<Post> findByIdInOrderByCreatedAtDesc(Collection<Long> ids);
    List<Post> findByAuthorIdOrderByCreatedAtDesc(Long authorId);
}


