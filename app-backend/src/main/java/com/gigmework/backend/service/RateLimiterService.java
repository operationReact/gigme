package com.gigmework.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** Simple in-memory rate limiter: limit N requests per key (email) in rolling window seconds. */
@Service
public class RateLimiterService {
    private static final class Bucket { int count; long windowStart; }
    private final Map<String,Bucket> buckets = new ConcurrentHashMap<>();

    @Value("${app.forgot.limit.count:5}")
    private int max;
    @Value("${app.forgot.limit.windowSeconds:900}") // 15m
    private int windowSeconds;

    public boolean allow(String key){
        if(key == null) key = "";
        long now = Instant.now().getEpochSecond();
        Bucket b = buckets.computeIfAbsent(key, k -> { Bucket nb = new Bucket(); nb.windowStart = now; return nb; });
        synchronized (b){
            if(now - b.windowStart >= windowSeconds){
                b.windowStart = now; b.count = 0; // reset window
            }
            if(b.count >= max){
                return false;
            }
            b.count++;
            return true;
        }
    }
}

