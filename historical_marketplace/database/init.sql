-- 1. Создаем типы ENUM (для PostgreSQL)
CREATE TYPE user_role AS ENUM ('buyer', 'seller', 'admin');
CREATE TYPE item_condition AS ENUM ('new', 'used', 'restored');
CREATE TYPE item_status AS ENUM ('active', 'sold', 'archived');
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'shipped', 'completed', 'cancelled');

-- 2. Таблица пользователей
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE, -- Исправлено Usersname
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    role user_role NOT NULL
);

-- 3. Профиль (связь 1:1)
CREATE TABLE Profile (
    profile_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE, -- Добавлен UNIQUE для связи 1:1
    full_name VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    bio TEXT,
    avatar_url VARCHAR(512),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

-- 4. Категории
CREATE TABLE Category (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT
);

-- 5. Товары
CREATE TABLE Products (
    item_id SERIAL PRIMARY KEY,
    seller_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    condition item_condition NOT NULL,
    creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Исправлено на TIMESTAMP
    status item_status NOT NULL,
    FOREIGN KEY (seller_id) REFERENCES Users(user_id),
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);

-- 6. Избранное
CREATE TABLE Favorites (
    favorite_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    item_id INT NOT NULL,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES Item(item_id) ON DELETE CASCADE,
    UNIQUE(user_id, item_id) -- Чтобы не было дублей
);

-- 7. Заказы
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    buyer_id INT NOT NULL,
    item_id INT NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_price DECIMAL(12,2) NOT NULL,
    status order_status NOT NULL,
    FOREIGN KEY (buyer_id) REFERENCES Users(user_id),
    FOREIGN KEY (item_id) REFERENCES Item(item_id)
);

-- 8. Сообщения
CREATE TABLE Message (
    message_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    item_id INT NOT NULL,
    content TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES Users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES Users(user_id),
    FOREIGN KEY (item_id) REFERENCES Item(item_id)
);

-- 9. Отзывы
CREATE TABLE Review (
    review_id SERIAL PRIMARY KEY,
    reviewer_id INT NOT NULL,
    reviewed_user_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5), -- Добавлена проверка
    comment TEXT,
    review_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reviewer_id) REFERENCES Users(user_id),
    FOREIGN KEY (reviewed_user_id) REFERENCES Users(user_id)
);

-- 10. Регистрация продавцов (заявки)
CREATE TABLE seller_registration (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    business_area VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    iin VARCHAR(12) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Данные продавца (подтвержденные)
CREATE TABLE seller (
    seller_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    business_area VARCHAR(100) NOT NULL,
    iin VARCHAR(12) NOT NULL UNIQUE,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);