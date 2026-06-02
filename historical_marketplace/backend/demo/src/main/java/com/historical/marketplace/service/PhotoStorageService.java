package com.historical.marketplace.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import java.util.UUID;

@Service
public class PhotoStorageService {
    private static final Path ROOT = Paths.get("Photos");

    public String store(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IOException("Empty file");
        }
        if (!Files.exists(ROOT)) {
            Files.createDirectories(ROOT);
        }
        String original = file.getOriginalFilename() != null ? file.getOriginalFilename() : "upload";
        String ext = extractExtension(original);
        String filename = UUID.randomUUID().toString() + (ext.isEmpty() ? "" : "." + ext);
        Path target = ROOT.resolve(filename).normalize();
        file.transferTo(target.toFile());
        return "/photos/" + filename;
    }

    private String extractExtension(String name) {
        int i = name.lastIndexOf('.');
        if (i == -1) return "";
        return name.substring(i + 1).toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "");
    }
}


