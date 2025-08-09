package com.study.snsapi.feed.representation.dto;

import jakarta.validation.constraints.NotBlank;

public record CreatePostRequest(@NotBlank String content) {}


