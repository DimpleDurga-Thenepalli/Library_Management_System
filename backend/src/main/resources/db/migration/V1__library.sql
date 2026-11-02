CREATE TABLE users (
 id BIGSERIAL PRIMARY KEY, full_name VARCHAR(120) NOT NULL, username VARCHAR(60) NOT NULL UNIQUE,
 email VARCHAR(254) NOT NULL UNIQUE, phone_number VARCHAR(30), password_hash VARCHAR(255) NOT NULL,
 role VARCHAR(20) NOT NULL CHECK(role IN ('ADMIN','CUSTOMER')), is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE books (
 id BIGSERIAL PRIMARY KEY, title VARCHAR(200) NOT NULL, author VARCHAR(150) NOT NULL,
 isbn VARCHAR(30) UNIQUE, genre VARCHAR(80) NOT NULL, description TEXT NOT NULL,
 price NUMERIC(12,2) NOT NULL CHECK(price >= 0), cover_image_path TEXT,
 publication_date DATE, status VARCHAR(20) NOT NULL CHECK(status IN ('DRAFT','PUBLISHED')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE chapters (
 id BIGSERIAL PRIMARY KEY, book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
 chapter_number INTEGER NOT NULL CHECK(chapter_number > 0), title VARCHAR(200) NOT NULL, content TEXT NOT NULL,
 CONSTRAINT chapter_order UNIQUE(book_id,chapter_number) DEFERRABLE INITIALLY DEFERRED,
 UNIQUE(id,book_id)
);
CREATE TABLE reading_progress (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
 chapter_id BIGINT NOT NULL, last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 FOREIGN KEY(chapter_id,book_id) REFERENCES chapters(id,book_id) ON DELETE CASCADE,
 UNIQUE(user_id,book_id)
);
CREATE INDEX books_status ON books(status);
CREATE INDEX chapters_book ON chapters(book_id);
