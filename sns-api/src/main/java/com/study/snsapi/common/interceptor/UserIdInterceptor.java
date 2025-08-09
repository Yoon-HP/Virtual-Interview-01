package com.study.snsapi.common.interceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Extracts X-User-Id header and stores it as request attribute for resolver.
 */
public class UserIdInterceptor implements HandlerInterceptor {
    public static final String REQ_ATTR_USER_ID = "__currentUserId";
    public static final String HEADER_USER_ID = "X-User-Id";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String header = request.getHeader(HEADER_USER_ID);
        if (header == null || header.isBlank()) return true;
        try {
            request.setAttribute(REQ_ATTR_USER_ID, Long.valueOf(header));
        } catch (NumberFormatException ignored) {}
        return true;
    }
}


