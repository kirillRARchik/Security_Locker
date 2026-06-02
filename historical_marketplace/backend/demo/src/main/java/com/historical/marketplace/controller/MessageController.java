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
@RequestMapping("/api/messages")
public class MessageController {
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final ProductRepository productRepository;

    public MessageController(MessageRepository messageRepository, UserRepository userRepository, ProductRepository productRepository) {
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.productRepository = productRepository;
    }

    public record CreateMessageRequest(@NotNull Long receiverId, @NotNull Long productId, @NotNull String content) {}

    @PostMapping
    public ResponseEntity<?> createMessage(Authentication auth, @RequestBody CreateMessageRequest req) {
        var sender = userRepository.findByEmail(auth.getName()).orElse(null);
        if (sender == null) return ResponseEntity.status(401).build();

        var receiver = userRepository.findById(req.receiverId()).orElse(null);
        if (receiver == null) return ResponseEntity.ok(Map.of("error", "..."));

        var product = productRepository.findById(req.productId()).orElse(null);
        if (product == null) return ResponseEntity.ok(Map.of("error", "..."));

        if (sender.getId().equals(receiver.getId())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Cannot message yourself"));
        }

        Message message = new Message();
        message.setSender(sender);
        message.setReceiver(receiver);
        message.setProduct(product);
        message.setContent(req.content());
        message.setSentAt(LocalDateTime.now());
        message = messageRepository.save(message);

        return ResponseEntity.ok(message);
    }

    @GetMapping("/conversations")
    public List<Product> getConversations(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return messageRepository.findConversationProducts(user.getId());
    }

    @GetMapping("/conversation/{userId}")
    public ResponseEntity<?> getConversation(Authentication auth, @PathVariable Long userId,
                                             @RequestParam Long productId) {
        var currentUser = userRepository.findByEmail(auth.getName()).orElse(null);
        if (currentUser == null) return ResponseEntity.status(401).build();

        if (!currentUser.getId().equals(userId)) {
            return ResponseEntity.status(403).body(Map.of("error", "Access denied"));
        }

        var otherUser = userRepository.findById(userId).orElse(null);
        if (otherUser == null) return ResponseEntity.notFound().build();

        // Get conversation between current user and other user about specific product
        var messages = messageRepository.findConversation(currentUser.getId(), otherUser.getId(), productId);
        return ResponseEntity.ok(Map.of("messages", messages));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(Authentication auth, @PathVariable Long id) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var message = messageRepository.findById(id).orElse(null);
        if (message == null) return ResponseEntity.notFound().build();

        if (!message.getReceiver().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("error", "Not your message"));
        }

        message.setReadAt(LocalDateTime.now());
        messageRepository.save(message);
        return ResponseEntity.ok(message);
    }

    @GetMapping("/unread/count")
    public ResponseEntity<?> getUnreadCount(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var unread = messageRepository.findUnreadMessagesByReceiverId(user.getId());
        return ResponseEntity.ok(Map.of("count", unread.size()));
    }
}

