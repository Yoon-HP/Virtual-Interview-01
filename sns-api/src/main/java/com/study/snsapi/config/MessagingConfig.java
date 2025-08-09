package com.study.snsapi.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MessagingConfig {

    @Bean
    public TopicExchange topicExchange() {
        return new TopicExchange("feed.events", true, false);
    }
}


