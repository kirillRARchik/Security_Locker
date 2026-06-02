package com.historical.marketplace.repo;

import com.historical.marketplace.model.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, Long> {
    @Query("SELECT DISTINCT m.product FROM Message m WHERE m.sender.id = :userId OR m.receiver.id = :userId")
    List<Product> findConversationProducts(@Param("userId") Long userId);
    
    @Query("SELECT m FROM Message m WHERE (m.sender.id = :userId1 AND m.receiver.id = :userId2) OR (m.sender.id = :userId2 AND m.receiver.id = :userId1) AND m.product.id = :productId ORDER BY m.sentAt ASC")
    List<Message> findConversation(@Param("userId1") Long userId1, @Param("userId2") Long userId2, @Param("productId") Long productId);
    
    @Query("SELECT m FROM Message m WHERE m.receiver.id = :userId AND m.readAt IS NULL")
    List<Message> findUnreadMessagesByReceiverId(@Param("userId") Long userId);
}