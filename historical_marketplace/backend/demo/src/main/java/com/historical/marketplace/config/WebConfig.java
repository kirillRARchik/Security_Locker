package com.historical.marketplace.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Serve files under Photos/ as /photos/**
        registry.addResourceHandler("/photos/**")
                .addResourceLocations("file:Photos/");
    }
}


