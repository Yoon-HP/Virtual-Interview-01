package com.study.snsapi.feed.representation;

import com.study.snsapi.common.annotation.CurrentUserId;
import com.study.snsapi.feed.domain.Post;
import com.study.snsapi.feed.representation.dto.CreatePostRequest;
import com.study.snsapi.feed.representation.dto.PostResponse;
import com.study.snsapi.feed.service.FeedService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/feeds")
@Validated
@RequiredArgsConstructor
public class FeedController {

    private final FeedService feedService;

    @PostMapping
    public ResponseEntity<PostResponse> create(
            @CurrentUserId final Long userId,
            @Valid @RequestBody final CreatePostRequest request
    ) {
        final Post post = feedService.createPost(userId, request.content());
        return ResponseEntity.status(HttpStatus.CREATED).body(PostResponse.from(post));
    }

    /**
     * 친구들의 포스트로 구성된 뉴스피드를 조회합니다.
     * Redis 캐시에서 친구들의 포스트 ID를 가져와 MySQL에서 실제 데이터를 조회합니다.
     */
    @GetMapping("/friends")
    public List<PostResponse> getFriendsFeed(@CurrentUserId final Long userId) {
        return feedService.getFriendsFeed(userId).stream()
                .map(PostResponse::from)
                .toList();
    }

    @GetMapping("/my")
    public List<PostResponse> getMyFeed(@CurrentUserId final Long userId) {
        return feedService.getMyFeed(userId).stream()
                .map(PostResponse::from)
                .toList();
    }

    @DeleteMapping("/{postId}")
    public ResponseEntity<Void> deletePost(
            @CurrentUserId final Long userId,
            @PathVariable final Long postId
    ) {
        feedService.deletePost(userId, postId);
        return ResponseEntity.noContent()
                .build();
    }
}
