package com.gigmework.backend.config;

import com.gigmework.backend.util.CognitoJwtVerifier;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jwt.JWTClaimsSet;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.io.IOException;
import java.text.ParseException;
import java.util.Map;
import java.util.Optional;

/**
 * WebSocket handshake interceptor that verifies an Authorization: Bearer <JWT> header
 * using CognitoJwtVerifier and stores selected claims in the WebSocket session attributes.
 */
@Component
public class JwtHandshakeInterceptor implements HandshakeInterceptor {
    private static final Logger log = LoggerFactory.getLogger(JwtHandshakeInterceptor.class);

    private final CognitoJwtVerifier verifier;

    public JwtHandshakeInterceptor(CognitoJwtVerifier verifier) {
        this.verifier = verifier;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request,
                                   ServerHttpResponse response,
                                   WebSocketHandler wsHandler,
                                   Map<String, Object> attributes) {
        try {
            String authHeader = Optional.ofNullable(request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION))
                    .orElse("");
            String token = extractBearerToken(authHeader);
            if (token == null) {
                setUnauthorized(response);
                return false;
            }

            JWTClaimsSet claims = verifier.verify(token);

            String sub = claims.getSubject();
            String email = claims.getStringClaim("email");
            if (sub == null || sub.isBlank()) {
                setUnauthorized(response);
                return false;
            }

            attributes.put("userId", sub);
            if (email != null && !email.isBlank()) {
                attributes.put("email", email);
            }
            return true;
        } catch (ParseException | JOSEException | IOException e) {
            log.debug("JWT verification failed: {}", e.getMessage());
            setUnauthorized(response);
            return false;
        } catch (Exception e) {
            log.warn("Unexpected error during WebSocket handshake auth", e);
            setUnauthorized(response);
            return false;
        }
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Exception exception) {
        // no-op
    }

    private static String extractBearerToken(String authHeader) {
        String prefix = "Bearer ";
        if (authHeader == null) return null;
        authHeader = authHeader.trim();
        if (authHeader.regionMatches(true, 0, prefix, 0, prefix.length())) {
            return authHeader.substring(prefix.length()).trim();
        }
        return null;
    }

    private static void setUnauthorized(ServerHttpResponse response) {
        try {
            response.setStatusCode(org.springframework.http.HttpStatus.UNAUTHORIZED);
        } catch (Exception ignored) {
        }
    }
}

