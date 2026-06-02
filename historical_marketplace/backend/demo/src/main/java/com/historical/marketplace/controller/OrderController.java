package com.historical.marketplace.controller;

import com.historical.marketplace.model.*;
import com.historical.marketplace.repo.*;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final CartItemRepository cartItemRepository;
    private final AddressRepository addressRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;

    public OrderController(OrderRepository orderRepository, OrderItemRepository orderItemRepository,
                          CartItemRepository cartItemRepository, AddressRepository addressRepository,
                          UserRepository userRepository, ProductRepository productRepository) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.cartItemRepository = cartItemRepository;
        this.addressRepository = addressRepository;
        this.userRepository = userRepository;
        this.productRepository = productRepository;
    }

    public record CreateOrderRequest(@NotNull Long addressId) {}

    @PostMapping
    public ResponseEntity<?> createOrder(Authentication auth, @RequestBody CreateOrderRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var address = addressRepository.findById(req.addressId()).orElse(null);
        if (address == null || !address.getUser().getId().equals(user.getId())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid address"));
        }

        var cartItems = cartItemRepository.findByUserId(user.getId());
        if (cartItems.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Cart is empty"));
        }

        double total = cartItems.stream().mapToDouble(i -> i.getProduct().getPrice() * i.getQuantity()).sum();

        Order order = new Order();
        order.setBuyer(user);
        order.setAddress(address);
        order.setTotalAmount(total);
        order.setOrderDate(LocalDateTime.now());
        order.setStatus(Order.OrderStatus.PENDING);
        order = orderRepository.save(order);

        for (var item : cartItems) {
            if (item.getProduct().getQuantity() < item.getQuantity()) {
                orderRepository.delete(order);
                return ResponseEntity.badRequest().body(Map.of("error", "Not enough quantity for " + item.getProduct().getName()));
            }

            OrderItem oi = new OrderItem();
            oi.setOrder(order);
            oi.setProduct(item.getProduct());
            oi.setQuantity(item.getQuantity());
            oi.setUnitPrice(item.getProduct().getPrice());
            orderItemRepository.save(oi);

            item.getProduct().setQuantity(item.getProduct().getQuantity() - item.getQuantity());
            productRepository.save(item.getProduct());
        }

        cartItemRepository.deleteAll(cartItems);
        return ResponseEntity.ok(order);
    }

    @GetMapping("/my")
    public List<Order> getMyOrders(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return orderRepository.findByBuyerIdOrderByOrderDateDesc(user.getId());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOrder(Authentication auth, @PathVariable Long id) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var order = orderRepository.findById(id).orElse(null);
        if (order == null) return ResponseEntity.notFound().build();

        if (!order.getBuyer().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("error", "Not your order"));
        }

        var items = orderItemRepository.findByOrderId(id);
        return ResponseEntity.ok(Map.of(
                "order", order,
                "items", items
        ));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateOrderStatus(Authentication auth, @PathVariable Long id, @RequestBody Map<String, String> body) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var order = orderRepository.findById(id).orElse(null);
        if (order == null) return ResponseEntity.notFound().build();

        // Only seller can update status
        var items = orderItemRepository.findByOrderId(id);
        if (items.isEmpty()) return ResponseEntity.badRequest().build();

        boolean isSeller = items.stream().anyMatch(item -> item.getProduct().getSeller().getUser().getId().equals(user.getId()));
        if (!isSeller) {
            return ResponseEntity.status(403).body(Map.of("error", "Not seller"));
        }

        try {
            Order.OrderStatus status = Order.OrderStatus.valueOf(body.get("status").toUpperCase());
            order.setStatus(status);

            if (status == Order.OrderStatus.SHIPPED && order.getShippingDate() == null) {
                order.setShippingDate(LocalDateTime.now());
            }
            if (status == Order.OrderStatus.DELIVERED && order.getDeliveryDate() == null) {
                order.setDeliveryDate(LocalDateTime.now());
            }

            orderRepository.save(order);
            return ResponseEntity.ok(order);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid status"));
        }
    }

    @PostMapping("/{id}/tracking")
    public ResponseEntity<?> addTrackingNumber(Authentication auth, @PathVariable Long id, @RequestBody Map<String, String> body) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var order = orderRepository.findById(id).orElse(null);
        if (order == null) return ResponseEntity.notFound().build();

        var items = orderItemRepository.findByOrderId(id);
        boolean isSeller = items.stream().anyMatch(item -> item.getProduct().getSeller().getUser().getId().equals(user.getId()));
        if (!isSeller) {
            return ResponseEntity.status(403).body(Map.of("error", "Not seller"));
        }

        order.setTrackingNumber(body.get("trackingNumber"));
        orderRepository.save(order);
        return ResponseEntity.ok(order);
    }

    @GetMapping("/{id}/tracking")
    public ResponseEntity<?> getTracking(Authentication auth, @PathVariable Long id) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var order = orderRepository.findById(id).orElse(null);
        if (order == null) return ResponseEntity.notFound().build();

        var items = orderItemRepository.findByOrderId(id);
        boolean isBuyer = order.getBuyer().getId().equals(user.getId());
        boolean isSeller = items.stream().anyMatch(item -> item.getProduct().getSeller().getUser().getId().equals(user.getId()));

        if (!isBuyer && !isSeller) {
            return ResponseEntity.status(403).body(Map.of("error", "Access denied"));
        }

        return ResponseEntity.ok(Map.of(
                "trackingNumber", order.getTrackingNumber(),
                "status", order.getStatus(),
                "shippingDate", order.getShippingDate(),
                "deliveryDate", order.getDeliveryDate()
        ));
    }
}

