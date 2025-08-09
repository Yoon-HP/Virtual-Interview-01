package com.study.snsapi.feed.messaging;

import lombok.RequiredArgsConstructor;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class PostEventPublisher {

    private final RabbitTemplate rabbitTemplate;
    private final TopicExchange exchange;

    @Value("${app.messaging.post.created-routing-key:post.created}")
    private String postCreatedRoutingKey;

    @Value("${app.messaging.post.deleted-routing-key:post.deleted}")
    private String postDeletedRoutingKey;

    public void publishPostCreated(Long postId, Long authorId, Timestamp createdAt) {
        Map<String, Object> payload = Map.of(
                "postId", postId,
                "authorId", authorId,
                "createdAt", createdAt.getTime()
        );
        rabbitTemplate.convertAndSend(exchange.getName(), postCreatedRoutingKey, payload);
    }

    public void publishPostDeleted(Long postId, Long authorId) {
        Map<String, Object> payload = Map.of(
                "postId", postId,
                "authorId", authorId,
                "deletedAt", System.currentTimeMillis()
        );
        rabbitTemplate.convertAndSend(exchange.getName(), postDeletedRoutingKey, payload);
    }
}


