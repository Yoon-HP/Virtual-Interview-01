package com.study.snsapi.feed.cache;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NewsfeedCacheService {

    private final StringRedisTemplate redis;

    private static String key(long userId) {
        return "friend_feed:" + userId;
    }

    public List<Long> getFriendFeed(long userId) {
        return redis.opsForZSet()
                .reverseRange(key(userId), 0, -1)  // 모든 데이터 조회
                .stream()
                .map(Long::valueOf)
                .toList();
    }
}


