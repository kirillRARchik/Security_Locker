-- Начальные данные для локальной разработки

-- Пользователь‑продавец
INSERT INTO Users (username, email, password_hash, phone, role)
VALUES (
    'demo_seller',
    'seller@example.com',
    '$2a$10$abcdefghijklmnopqrstuv', -- заглушка bcrypt-хеша, при необходимости замени на реальный
    '+7 700 000 00 00',
    'seller'
)
ON CONFLICT (username) DO NOTHING;

-- Профиль продавца
INSERT INTO Profile (user_id, full_name, city, country, bio, avatar_url)
SELECT
    user_id,
    'Demo Seller',
    'Almaty',
    'Kazakhstan',
    'Демонстрационный продавец для теста интерфейса.',
    'https://example.com/avatar.png'
FROM Users
WHERE username = 'demo_seller'
ON CONFLICT (user_id) DO NOTHING;

-- Категория товара
INSERT INTO Category (name, description)
VALUES (
    'Антиквариат',
    'Исторические и коллекционные предметы.'
)
ON CONFLICT (name) DO NOTHING;

-- Демонстрационный товар
INSERT INTO Products (seller_id, title, description, category_id, price, condition, status)
SELECT
    u.user_id,
    'Старинная монета XIX века',
    'Оригинальная коллекционная монета XIX века в хорошем состоянии.',
    c.category_id,
    15000.00,
    'used',
    'active'
FROM Users u
JOIN Category c ON c.name = 'Антиквариат'
WHERE u.username = 'demo_seller'
ON CONFLICT DO NOTHING;

