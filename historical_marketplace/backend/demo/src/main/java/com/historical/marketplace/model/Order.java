package com.historical.marketplace.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "buyer_id")
    private User buyer;

    @ManyToOne(optional = false)
    @JoinColumn(name = "address_id")
    private Address address;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status = OrderStatus.PENDING;

    private Double totalAmount;
    private LocalDateTime orderDate;
    private LocalDateTime shippingDate;
    private LocalDateTime deliveryDate;
    private String trackingNumber;

    public enum OrderStatus {
        PENDING, PAID, PROCESSING, SHIPPED, DELIVERED, CANCELLED
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public User getBuyer() { return buyer; }
    public void setBuyer(User buyer) { this.buyer = buyer; }
    public Address getAddress() { return address; }
    public void setAddress(Address address) { this.address = address; }
    public OrderStatus getStatus() { return status; }
    public void setStatus(OrderStatus status) { this.status = status; }
    public Double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Double totalAmount) { this.totalAmount = totalAmount; }
    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }
    public LocalDateTime getShippingDate() { return shippingDate; }
    public void setShippingDate(LocalDateTime shippingDate) { this.shippingDate = shippingDate; }
    public LocalDateTime getDeliveryDate() { return deliveryDate; }
    public void setDeliveryDate(LocalDateTime deliveryDate) { this.deliveryDate = deliveryDate; }
    public String getTrackingNumber() { return trackingNumber; }
    public void setTrackingNumber(String trackingNumber) { this.trackingNumber = trackingNumber; }
}

