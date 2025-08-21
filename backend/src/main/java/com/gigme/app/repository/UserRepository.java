package com.gigme.app.repository;

import com.gigme.app.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for {@link User} entities.  Extending
 * {@link JpaRepository} provides CRUD operations out of the box.
 */
public interface UserRepository extends JpaRepository<User, Long> {
}