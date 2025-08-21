package com.gigme.app.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Simple user entity for demonstration purposes.  A user can be either a
 * CLIENT (someone who posts gigs) or a FREELANCER (someone who bids on gigs).
 */
@Entity
@Data
@NoArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String username;
    private String email;
    private String role; // CLIENT or FREELANCER
}