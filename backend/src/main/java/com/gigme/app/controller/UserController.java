package com.gigme.app.controller;

import com.gigme.app.model.User;
import com.gigme.app.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for managing users.  Provides basic endpoints for
 * registration and listing users.  In a real application you would want
 * to add validation and authentication.
 */
@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {
    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Register a new user.  Expects a JSON body containing username,
     * email and role (CLIENT or FREELANCER).  Returns the persisted
     * user entity.
     */
    @PostMapping("/register")
    public ResponseEntity<User> register(@RequestBody User user) {
        return ResponseEntity.ok(userRepository.save(user));
    }

    /**
     * List all users in the system.
     */
    @GetMapping
    public List<User> getUsers() {
        return userRepository.findAll();
    }
}