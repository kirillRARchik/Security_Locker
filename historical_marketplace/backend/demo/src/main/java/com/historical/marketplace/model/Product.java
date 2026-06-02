package com.historical.marketplace.model;

import jakarta.persistence.*;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "seller_id")
    private SellerProfile seller;

    private String photoUrl;
    private String name;
    private Double price;
    private Integer quantity;
    private Boolean customMade; // made to order
    private String sizeMeasure; // dimensional measure if any
    private String manufacturingMethod; // choice of method if any
    private String category; // product category
    private String authenticityCertificate; // URL or text for certificate
    private String period; // historical era
    private String material; // materials used
    private Boolean verifiedByAdmin; // admin verification flag

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public SellerProfile getSeller() { return seller; }
    public void setSeller(SellerProfile seller) { this.seller = seller; }
    public String getPhotoUrl() { return photoUrl; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public Boolean getCustomMade() { return customMade; }
    public void setCustomMade(Boolean customMade) { this.customMade = customMade; }
    public String getSizeMeasure() { return sizeMeasure; }
    public void setSizeMeasure(String sizeMeasure) { this.sizeMeasure = sizeMeasure; }
    public String getManufacturingMethod() { return manufacturingMethod; }
    public void setManufacturingMethod(String manufacturingMethod) { this.manufacturingMethod = manufacturingMethod; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getAuthenticityCertificate() { return authenticityCertificate; }
    public void setAuthenticityCertificate(String authenticityCertificate) { this.authenticityCertificate = authenticityCertificate; }
    public String getPeriod() { return period; }
    public void setPeriod(String period) { this.period = period; }
    public String getMaterial() { return material; }
    public void setMaterial(String material) { this.material = material; }
    public Boolean getVerifiedByAdmin() { return verifiedByAdmin; }
    public void setVerifiedByAdmin(Boolean verifiedByAdmin) { this.verifiedByAdmin = verifiedByAdmin; }
}