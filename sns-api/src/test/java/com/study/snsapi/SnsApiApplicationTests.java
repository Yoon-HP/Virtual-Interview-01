package com.study.snsapi;

import org.junit.jupiter.api.Test;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.core.StringRedisTemplate;

import static org.mockito.Mockito.mock;

@SpringBootTest
class SnsApiApplicationTests {

	@TestConfiguration
	static class TestConfig {
		@Bean
		@Primary
		public RabbitTemplate rabbitTemplate() {
			return mock(RabbitTemplate.class);
		}
		
		@Bean
		@Primary
		public StringRedisTemplate stringRedisTemplate() {
			return mock(StringRedisTemplate.class);
		}
	}

	@Test
	void contextLoads() {
	}

}
