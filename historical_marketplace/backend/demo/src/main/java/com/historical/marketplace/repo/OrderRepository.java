package com.historical.marketplace.repo;

import com.historical.marketplace.model.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByBuyerIdOrderByOrderDateDesc(Long buyerId);
    List<Order> findByAddressUserIdOrderByOrderDateDesc(Long sellerId);
}
