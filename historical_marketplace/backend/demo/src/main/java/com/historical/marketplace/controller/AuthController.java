package com.historical.marketplace.controller;

import com.historical.marketplace.model.User;
import com.historical.marketplace.repo.UserRepository;
import com.historical.marketplace.security.JwtService;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthController(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public record RegisterRequest(@Email String email, @NotBlank String password, String displayName) {}
    public record AuthResponse(String token) {}
    public record LoginRequest(@Email String email, @NotBlank String password) {}

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (userRepository.findByEmail(req.email()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email already in use"));
        }
        User u = new User();
        u.setEmail(req.email());
        u.setPasswordHash(passwordEncoder.encode(req.password()));
        u.setDisplayName(req.displayName());
        u.setRoles(Set.of("USER"));
        userRepository.save(u);
        String token = jwtService.generateToken(u.getEmail(), Map.of("roles", u.getRoles(), "userId", u.getId()));
        return ResponseEntity.ok(new AuthResponse(token));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        var user = userRepository.findByEmail(req.email()).orElse(null);
        if (user == null || !passwordEncoder.matches(req.password(), user.getPasswordHash())) {
            return ResponseEntity.status(401).body(Map.of("error", "Invalid credentials"));
        }
        String token = jwtService.generateToken(user.getEmail(), Map.of("roles", user.getRoles(), "userId", user.getId()));
        return ResponseEntity.ok(new AuthResponse(token));
    }
}


