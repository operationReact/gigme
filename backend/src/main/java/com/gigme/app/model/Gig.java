package com.gigme.app.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a job posting on GigMe.  A gig is posted by a client and
 * includes a title, description and budget.  The association to a client
 * is optional here; a client can be set by providing a User with an id.
 */
@Entity
@Data
@NoArgsConstructor
public class Gig {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;
    private Double budget;

    @ManyToOne
    private User client;
}