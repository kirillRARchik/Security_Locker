package com.historical.marketplace.controller;

import com.historical.marketplace.model.*;
import com.historical.marketplace.repo.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {
    private final ReviewRepository reviewRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;

    public ReviewController(ReviewRepository reviewRepository, ProductRepository productRepository,
                           UserRepository userRepository, OrderRepository orderRepository,
                           OrderItemRepository orderItemRepository) {
        this.reviewRepository = reviewRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
    }

    public record CreateReviewRequest(@NotNull Long productId, @Min(1) @Max(5) Integer rating, String comment, String reviewPhotoUrl) {}

    @PostMapping
    public ResponseEntity<?> createReview(Authentication auth, @RequestBody CreateReviewRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var product = productRepository.findById(req.productId()).orElse(null);
        if (product == null) return ResponseEntity.notFound().build();

        // Check if user already reviewed this product
        if (reviewRepository.findByProductIdAndUserId(req.productId(), user.getId()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("error", "You already reviewed this product"));
        }

        // Check if user purchased this product (verified purchase)
        boolean verifiedPurchase = false;
        var userOrders = orderRepository.findByBuyerIdOrderByOrderDateDesc(user.getId());
        for (var order : userOrders) {
            if (order.getStatus() == Order.OrderStatus.DELIVERED) {
                var items = orderItemRepository.findByOrderId(order.getId());
                verifiedPurchase = items.stream().anyMatch(item -> item.getProduct().getId().equals(req.productId()));
                if (verifiedPurchase) break;
            }
        }

        Review review = new Review();
        review.setProduct(product);
        review.setUser(user);
        review.setSeller(product.getSeller());
        review.setRating(req.rating());
        review.setComment(req.comment());
        review.setReviewPhotoUrl(req.reviewPhotoUrl());
        review.setVerifiedPurchase(verifiedPurchase);
        review.setReviewDate(LocalDateTime.now());
        reviewRepository.save(review);

        return ResponseEntity.ok(review);
    }

    @GetMapping("/product/{productId}")
    public List<Review> getProductReviews(@PathVariable Long productId) {
        return reviewRepository.findByProductId(productId);
    }

    @GetMapping("/seller/{sellerId}")
    public List<Review> getSellerReviews(@PathVariable Long sellerId) {
        return reviewRepository.findBySellerId(sellerId);
    }
}

