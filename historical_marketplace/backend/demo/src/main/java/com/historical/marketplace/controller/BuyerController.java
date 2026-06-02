package com.historical.marketplace.controller;

import com.historical.marketplace.model.*;
import com.historical.marketplace.repo.*;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/buyer")
public class BuyerController {
    private final UserRepository userRepository;
    private final FavoriteRepository favoriteRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final AddressRepository addressRepository;

    public BuyerController(UserRepository userRepository, FavoriteRepository favoriteRepository, CartItemRepository cartItemRepository, ProductRepository productRepository, AddressRepository addressRepository) {
        this.userRepository = userRepository;
        this.favoriteRepository = favoriteRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.addressRepository = addressRepository;
    }

    public record IdRequest(@NotNull Long id) {}
    public record QuantityRequest(@NotNull Long productId, @NotNull Integer quantity) {}
    public record AddressRequest(String recipientName, String line1, String line2, String city, String region, String postalCode, String country) {}

    // Favorites
    @PostMapping("/favorites")
    public ResponseEntity<?> addFavorite(Authentication auth, @RequestBody IdRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        var product = productRepository.findById(req.id()).orElse(null);
        if (user == null || product == null) return ResponseEntity.badRequest().build();
        favoriteRepository.findByUserIdAndProductId(user.getId(), product.getId()).ifPresent(f -> {});
        if (favoriteRepository.findByUserIdAndProductId(user.getId(), product.getId()).isEmpty()) {
            Favorite f = new Favorite();
            f.setUser(user);
            f.setProduct(product);
            favoriteRepository.save(f);
        }
        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    @DeleteMapping("/favorites/{productId}")
    public ResponseEntity<?> removeFavorite(Authentication auth, @PathVariable Long productId) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();
        favoriteRepository.findByUserIdAndProductId(user.getId(), productId).ifPresent(favoriteRepository::delete);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/favorites")
    public List<Favorite> listFavorites(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return favoriteRepository.findByUserId(user.getId());
    }

    // Cart
    @PostMapping("/cart")
    public ResponseEntity<?> addToCart(Authentication auth, @RequestBody QuantityRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        var product = productRepository.findById(req.productId()).orElse(null);
        if (user == null || product == null) return ResponseEntity.badRequest().build();
        var existing = cartItemRepository.findByUserIdAndProductId(user.getId(), product.getId()).orElse(null);
        if (existing == null) {
            CartItem item = new CartItem();
            item.setUser(user);
            item.setProduct(product);
            item.setQuantity(req.quantity());
            cartItemRepository.save(item);
        } else {
            existing.setQuantity(req.quantity());
            cartItemRepository.save(existing);
        }
        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    @DeleteMapping("/cart/{productId}")
    public ResponseEntity<?> removeFromCart(Authentication auth, @PathVariable Long productId) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();
        cartItemRepository.findByUserIdAndProductId(user.getId(), productId).ifPresent(cartItemRepository::delete);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/cart")
    public List<CartItem> listCart(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return cartItemRepository.findByUserId(user.getId());
    }

    // Addresses
    @PostMapping("/addresses")
    public ResponseEntity<?> addAddress(Authentication auth, @RequestBody AddressRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();
        Address a = new Address();
        a.setUser(user);
        a.setRecipientName(req.recipientName());
        a.setLine1(req.line1());
        a.setLine2(req.line2());
        a.setCity(req.city());
        a.setRegion(req.region());
        a.setPostalCode(req.postalCode());
        a.setCountry(req.country());
        addressRepository.save(a);
        return ResponseEntity.ok(a);
    }

    @GetMapping("/addresses")
    public List<Address> listAddresses(Authentication auth) {
        var user = userRepository.findByEmail(auth.getName()).orElseThrow();
        return addressRepository.findByUserId(user.getId());
    }

    // Checkout summary
    public record CheckoutRequest(@NotNull Long addressId) {}
    public record CheckoutSummary(Double totalAmount, String eta) {}

    @PostMapping("/checkout/summary")
    public ResponseEntity<?> checkoutSummary(Authentication auth, @RequestBody CheckoutRequest req) {
        var user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) return ResponseEntity.status(401).build();
        var address = addressRepository.findById(req.addressId()).orElse(null);
        if (address == null || !address.getUser().getId().equals(user.getId())) return ResponseEntity.badRequest().body(Map.of("error", "Invalid address"));
        var items = cartItemRepository.findByUserId(user.getId());
        double total = items.stream().mapToDouble(i -> i.getProduct().getPrice() * i.getQuantity()).sum();
        String eta = LocalDate.now().plusDays(7).toString();
        return ResponseEntity.ok(new CheckoutSummary(total, eta));
    }
}


