package com.study.snsapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class SnsApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(SnsApiApplication.class, args);
	}

}
