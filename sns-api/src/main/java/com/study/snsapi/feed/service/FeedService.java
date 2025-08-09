package com.study.snsapi.feed.service;

import com.study.snsapi.feed.cache.NewsfeedCacheService;
import com.study.snsapi.feed.domain.Post;
import com.study.snsapi.feed.messaging.PostEventPublisher;
import com.study.snsapi.feed.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FeedService {

    private final PostRepository postRepository;
    private final PostEventPublisher postEventPublisher;
    private final NewsfeedCacheService newsfeedCacheService;

    @Transactional
    public Post createPost(final Long authorId, final String content) {
        final Post post = Post.builder().authorId(authorId).content(content)
                .build();
        final Post saved = postRepository.save(post);
        postEventPublisher.publishPostCreated(saved.getId(), saved.getAuthorId(), saved.getCreatedAt());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<Post> getFriendsFeed(final Long userId) {
        final List<Long> ids = newsfeedCacheService.getFriendFeed(userId);
        if (ids.isEmpty()) return List.of();
        return postRepository.findByIdInOrderByCreatedAtDesc(ids);
    }

    @Transactional(readOnly = true)
    public List<Post> getMyFeed(final Long userId) {
        return postRepository.findByAuthorIdOrderByCreatedAtDesc(userId);
    }

    @Transactional
    public void deletePost(final Long userId, final Long postId) {
        final Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Post not found"));

        if (!post.getAuthorId().equals(userId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Cannot delete other user's post");
        }

        postRepository.delete(post);
        postEventPublisher.publishPostDeleted(postId, userId);
    }
}
