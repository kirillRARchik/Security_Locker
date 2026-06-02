package com.historical.marketplace.controller;

import com.historical.marketplace.model.*;
import com.historical.marketplace.repo.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/seller")
public class SellerController {
    private final UserRepository userRepository;
    private final SellerProfileRepository sellerProfileRepository;
    private final ProductRepository productRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;

    public SellerController(UserRepository userRepository, SellerProfileRepository sellerProfileRepository,
                           ProductRepository productRepository, OrderItemRepository orderItemRepository,
                           OrderRepository orderRepository, PaymentRepository paymentRepository) {
        this.userRepository = userRepository;
        this.sellerProfileRepository = sellerProfileRepository;
        this.productRepository = productRepository;
        this.orderItemRepository = orderItemRepository;
        this.orderRepository = orderRepository;
        this.paymentRepository = paymentRepository;
    }

    public record BecomeSellerRequest(@NotBlank String country,
                                      @NotBlank String companyType,
                                      @NotBlank String activityField,
                                      @Email String companyEmail) {}

    @PostMapping("/become")
    public ResponseEntity<?> becomeSeller(Authentication auth, @RequestBody BecomeSellerRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();
        if (sellerProfileRepository.findByUserId(user.getId()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Already a seller"));
        }
        SellerProfile sp = new SellerProfile();
        sp.setUser(user);
        sp.setCountry(req.country());
        sp.setCompanyType(req.companyType());
        sp.setActivityField(req.activityField());
        sp.setCompanyEmail(req.companyEmail());
        sellerProfileRepository.save(sp);
        var roles = user.getRoles();
        roles.add("SELLER");
        user.setRoles(roles);
        userRepository.save(user);
        return ResponseEntity.ok(Map.of("message", "Now seller", "sellerProfileId", sp.getId()));
    }

    @GetMapping("/dashboard/stats")
    public ResponseEntity<?> getStats(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var seller = sellerProfileRepository.findByUserId(user.getId()).orElse(null);
        if (seller == null) return ResponseEntity.status(403).body(Map.of("error", "Not a seller"));

        var products = productRepository.findBySellerId(seller.getId());
        var allOrders = orderRepository.findAll();

        List<Order> sellerOrders = new ArrayList<>();
        for (var order : allOrders) {
            var items = orderItemRepository.findByOrderId(order.getId());
            if (items.stream().anyMatch(item -> item.getProduct().getSeller().getId().equals(seller.getId()))) {
                sellerOrders.add(order);
            }
        }

        double totalRevenue = 0.0;
        long completedOrders = 0;
        for (var order : sellerOrders) {
            if (order.getStatus() == Order.OrderStatus.DELIVERED) {
                var items = orderItemRepository.findByOrderId(order.getId());
                for (var item : items) {
                    if (item.getProduct().getSeller().getId().equals(seller.getId())) {
                        totalRevenue += item.getUnitPrice() * item.getQuantity();
                        completedOrders++;
                    }
                }
            }
        }

        Map<String, Object> stats = new HashMap<>();
        stats.put("totalProducts", products.size());
        stats.put("totalRevenue", totalRevenue);
        stats.put("completedOrders", completedOrders);
        stats.put("pendingOrders", sellerOrders.stream().filter(o -> o.getStatus() == Order.OrderStatus.PAID || o.getStatus() == Order.OrderStatus.PROCESSING).count());
        stats.put("activeProducts", products.size());

        return ResponseEntity.ok(stats);
    }

    @GetMapping("/dashboard/orders")
    public ResponseEntity<?> getDashboardOrders(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var seller = sellerProfileRepository.findByUserId(user.getId()).orElse(null);
        if (seller == null) return ResponseEntity.status(403).body(Map.of("error", "Not a seller"));

        var allOrders = orderRepository.findAll();
        List<Map<String, Object>> sellerOrders = new ArrayList<>();

        for (var order : allOrders) {
            var items = orderItemRepository.findByOrderId(order.getId());
            var sellerItems = items.stream()
                    .filter(item -> item.getProduct().getSeller().getId().equals(seller.getId()))
                    .toList();

            if (!sellerItems.isEmpty()) {
                Map<String, Object> orderInfo = new HashMap<>();
                orderInfo.put("order", order);
                orderInfo.put("items", sellerItems);
                sellerOrders.add(orderInfo);
            }
        }

        return ResponseEntity.ok(sellerOrders);
    }

    @GetMapping("/dashboard/finances")
    public ResponseEntity<?> getFinances(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var seller = sellerProfileRepository.findByUserId(user.getId()).orElse(null);
        if (seller == null) return ResponseEntity.status(403).body(Map.of("error", "Not a seller"));

        var allOrders = orderRepository.findAll();
        List<Map<String, Object>> paymentHistory = new ArrayList<>();

        for (var order : allOrders) {
            var items = orderItemRepository.findByOrderId(order.getId());
            var sellerItems = items.stream()
                    .filter(item -> item.getProduct().getSeller().getId().equals(seller.getId()))
                    .toList();

            if (!sellerItems.isEmpty() && order.getStatus() == Order.OrderStatus.DELIVERED) {
                var payment = paymentRepository.findByOrderId(order.getId());
                if (payment.isPresent()) {
                    Map<String, Object> financeEntry = new HashMap<>();
                    financeEntry.put("orderId", order.getId());
                    financeEntry.put("amount", payment.get().getAmount());
                    financeEntry.put("date", payment.get().getPaymentDate());
                    financeEntry.put("status", payment.get().getStatus());
                    paymentHistory.add(financeEntry);
                }
            }
        }

        return ResponseEntity.ok(paymentHistory);
    }
}


