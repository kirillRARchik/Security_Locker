package com.historical.marketplace.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reviews")
public class Review {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "product_id")
    private Product product;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "seller_id")
    private SellerProfile seller;

    @Column(nullable = false)
    private Integer rating; // 1-5

    private String comment;
    private String reviewPhotoUrl;
    private Boolean verifiedPurchase = false;
    private LocalDateTime reviewDate;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Product getProduct() { return product; }
    public void setProduct(Product product) { this.product = product; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public SellerProfile getSeller() { return seller; }
    public void setSeller(SellerProfile seller) { this.seller = seller; }
    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }
    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
    public String getReviewPhotoUrl() { return reviewPhotoUrl; }
    public void setReviewPhotoUrl(String reviewPhotoUrl) { this.reviewPhotoUrl = reviewPhotoUrl; }
    public Boolean getVerifiedPurchase() { return verifiedPurchase; }
    public void setVerifiedPurchase(Boolean verifiedPurchase) { this.verifiedPurchase = verifiedPurchase; }
    public LocalDateTime getReviewDate() { return reviewDate; }
    public void setReviewDate(LocalDateTime reviewDate) { this.reviewDate = reviewDate; }
}

