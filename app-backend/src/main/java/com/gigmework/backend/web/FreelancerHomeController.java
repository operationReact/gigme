package com.gigmework.backend.web;

import com.gigmework.backend.service.FreelancerHomeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/freelancers")
public class FreelancerHomeController {
    private final FreelancerHomeService homeService;

    public FreelancerHomeController(FreelancerHomeService homeService) { this.homeService = homeService; }

    @GetMapping("/{userId}/home")
    public ResponseEntity<?> home(@PathVariable Long userId) {
        try {
            return ResponseEntity.ok(homeService.getHome(userId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }
}

