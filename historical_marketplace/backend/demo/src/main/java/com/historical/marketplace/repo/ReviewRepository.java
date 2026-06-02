package com.historical.marketplace.repo;

import com.historical.marketplace.model.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByProductId(Long productId);
    List<Review> findBySellerId(Long sellerId);
    Optional<Review> findByProductIdAndUserId(Long productId, Long userId);
}

