package com.gigme.app.controller;

import com.gigme.app.model.Gig;
import com.gigme.app.model.User;
import com.gigme.app.repository.GigRepository;
import com.gigme.app.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST controller for managing gigs.  Supports creating a gig and listing
 * all gigs.  When creating a gig the client relationship may be established
 * by providing a user with an ID in the request body.
 */
@RestController
@RequestMapping("/api/gigs")
@CrossOrigin(origins = "*")
public class GigController {
    private final GigRepository gigRepository;
    private final UserRepository userRepository;

    public GigController(GigRepository gigRepository, UserRepository userRepository) {
        this.gigRepository = gigRepository;
        this.userRepository = userRepository;
    }

    /**
     * Create a new gig.  A JSON body with title, description, budget and
     * optionally a client object containing an ID is expected.  If a client
     * is provided, it is looked up and associated with the gig.
     */
    @PostMapping
    public ResponseEntity<Gig> createGig(@RequestBody Gig gig) {
        // Look up client if an ID was provided
        if (gig.getClient() != null && gig.getClient().getId() != null) {
            User client = userRepository.findById(gig.getClient().getId())
                    .orElseThrow(() -> new IllegalArgumentException("Invalid client ID"));
            gig.setClient(client);
        }
        return ResponseEntity.ok(gigRepository.save(gig));
    }

    /**
     * Return a list of all gigs in the system.
     */
    @GetMapping
    public List<Gig> getGigs() {
        return gigRepository.findAll();
    }
}