package com.historical.marketplace.model;

import jakarta.persistence.*;

@Entity
@Table(name = "seller_profiles")
public class SellerProfile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String country;
    private String companyType; // sole proprietor, JSC, LLP, self-employed
    private String activityField;
    @Column(unique = true)
    private String companyEmail;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    public String getCompanyType() { return companyType; }
    public void setCompanyType(String companyType) { this.companyType = companyType; }
    public String getActivityField() { return activityField; }
    public void setActivityField(String activityField) { this.activityField = activityField; }
    public String getCompanyEmail() { return companyEmail; }
    public void setCompanyEmail(String companyEmail) { this.companyEmail = companyEmail; }
}


