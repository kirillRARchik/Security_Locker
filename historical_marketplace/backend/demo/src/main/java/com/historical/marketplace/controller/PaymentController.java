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
@RequestMapping("/api/payments")
public class PaymentController {
    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    public PaymentController(PaymentRepository paymentRepository, OrderRepository orderRepository, UserRepository userRepository) {
        this.paymentRepository = paymentRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
    }

    public record CreatePaymentRequest(@NotNull Long orderId, String paymentMethod, String currency) {}

    @PostMapping
    public ResponseEntity<?> createPayment(Authentication auth, @RequestBody CreatePaymentRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var order = orderRepository.findById(req.orderId()).orElse(null);
        if (order == null) return ResponseEntity.notFound().build();

        if (!order.getBuyer().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("error", "Not your order"));
        }

        if (order.getStatus() != Order.OrderStatus.PENDING) {
            return ResponseEntity.badRequest().body(Map.of("error", "Order already processed"));
        }

        Payment payment = new Payment();
        payment.setOrder(order);
        payment.setUser(user);
        payment.setAmount(order.getTotalAmount());
        payment.setCurrency(req.currency() != null ? req.currency() : "USD");
        payment.setPaymentMethod(req.paymentMethod() != null ? req.paymentMethod() : "CARD");
        payment.setStatus(Payment.PaymentStatus.PROCESSING);
        payment.setPaymentDate(LocalDateTime.now());
        payment = paymentRepository.save(payment);

        // Simulate payment processing - in real app, integrate with payment gateway
        try {
            Thread.sleep(1000); // Simulate API call
            payment.setStatus(Payment.PaymentStatus.COMPLETED);
            payment.setTransactionId("TXN_" + System.currentTimeMillis());
            order.setStatus(Order.OrderStatus.PAID);
            orderRepository.save(order);
            payment = paymentRepository.save(payment);
        } catch (InterruptedException e) {
            payment.setStatus(Payment.PaymentStatus.FAILED);
            paymentRepository.save(payment);
        }

        return ResponseEntity.ok(payment);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPayment(Authentication auth, @PathVariable Long id) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var payment = paymentRepository.findById(id).orElse(null);
        if (payment == null) return ResponseEntity.notFound().build();

        if (!payment.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("error", "Not your payment"));
        }

        return ResponseEntity.ok(payment);
    }

    @GetMapping("/my")
    public List<Payment> getMyPayments(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return paymentRepository.findByUserId(user.getId());
    }
}

