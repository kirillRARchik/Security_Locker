package com.historical.marketplace.controller;

import com.historical.marketplace.model.*;
import com.historical.marketplace.repo.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationController(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @GetMapping
    public List<Notification> getMyNotifications(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
    }

    @GetMapping("/unread")
    public List<Notification> getUnreadNotifications(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return notificationRepository.findByUserIdAndReadFalseOrderByCreatedAtDesc(user.getId());
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(Authentication auth, @PathVariable Long id) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var notification = notificationRepository.findById(id).orElse(null);
        if (notification == null) return ResponseEntity.notFound().build();

        if (!notification.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("error", "Not your notification"));
        }

        notification.setRead(true);
        notificationRepository.save(notification);
        return ResponseEntity.ok(notification);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNotification(Authentication auth, @PathVariable Long id) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();

        var notification = notificationRepository.findById(id).orElse(null);
        if (notification == null) return ResponseEntity.notFound().build();

        if (!notification.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body(Map.of("error", "Not your notification"));
        }

        notificationRepository.delete(notification);
        return ResponseEntity.noContent().build();
    }
}

