package com.gigme.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Entry point for the GigMe backend.  This class bootstraps the Spring
 * application context.  Running this will start an embedded Tomcat server
 * exposing the REST API defined in the controllers under
 * {@code com.gigme.app.controller}.
 */
@SpringBootApplication
public class GigmeApplication {

    public static void main(String[] args) {
        SpringApplication.run(GigmeApplication.class, args);
    }
}