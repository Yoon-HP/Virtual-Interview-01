package com.study.snsapi.feed.representation.dto;

import com.study.snsapi.feed.domain.Post;

import java.sql.Timestamp;

public record PostResponse(Long id, Long authorId, String content, Timestamp createdAt, Timestamp updatedAt) {
    public static PostResponse from(Post p) {
        return new PostResponse(p.getId(), p.getAuthorId(), p.getContent(), p.getCreatedAt(), p.getUpdatedAt());
    }
}
