from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from flask import Flask, abort, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash, generate_password_hash

APP_DIR = Path(__file__).resolve().parent / "app"
DB_PATH = Path(__file__).resolve().parent / "security_locker.sqlite3"

app = Flask(
    __name__,
    template_folder=str(APP_DIR / "templates"),
    static_folder=str(APP_DIR / "static"),
)

# Dev-only secret key (replace for production)
app.secret_key = "dev-secret-key-change-me"


@dataclass(frozen=True)
class User:
    id: int
    email: str


def _connect_db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def _init_db() -> None:
    with _connect_db() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS dashboard_stats (
                user_id INTEGER PRIMARY KEY,
                progress_percent INTEGER NOT NULL DEFAULT 0,
                xp INTEGER NOT NULL DEFAULT 0,
                topics_done INTEGER NOT NULL DEFAULT 0,
                sections_done INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS achievements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                amount INTEGER NOT NULL,
                label TEXT NOT NULL,
                sort_order INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS test_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                section TEXT NOT NULL,
                max_points INTEGER NOT NULL,
                best_result INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS courses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                module TEXT NOT NULL,
                lessons_count INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL DEFAULT 'draft',
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            );
            """
        )
        _seed_courses(conn)


def _seed_user_data(conn: sqlite3.Connection, user_id: int) -> None:
    conn.execute(
        "INSERT OR IGNORE INTO dashboard_stats (user_id, progress_percent, xp, topics_done, sections_done) VALUES (?, 0, 0, 0, 0)",
        (user_id,),
    )
    # Achievements (placeholders to match current UI)
    conn.executemany(
        "INSERT INTO achievements (user_id, amount, label, sort_order) VALUES (?, ?, ?, ?)",
        [
            (user_id, 1, "Пока пусто", 1),
        ],
    )
    # Test history (placeholders to match current table)
    conn.executemany(
        "INSERT INTO test_history (user_id, title, section, max_points, best_result) VALUES (?, ?, ?, ?, ?)",
        [
            (user_id, "Создание и проверка надёжности", "Пароли и аутентификация", 13, 0),
            (user_id, "Двухфакторная аутентификация", "Пароли и аутентификация", 14, 0),
            (user_id, "Фейковые письма и ссылки", "Фишинг и социальная инженерия", 7, 0),
            (user_id, "Защита WiFI", "Сетевая безопасность", 6, 0),
            (user_id, "Работа VPN", "Сетевая безопасность", 31, 0),
        ],
    )


def _seed_courses(conn: sqlite3.Connection) -> None:
    count = conn.execute("SELECT COUNT(*) AS c FROM courses").fetchone()
    if count and int(count["c"]) > 0:
        return
    conn.executemany(
        "INSERT INTO courses (title, module, lessons_count, status, updated_at) VALUES (?, ?, ?, ?, ?)",
        [
            ("Пароли и аутентификация", "Модуль 1", 2, "published", "2023-04-17"),
            ("Фишинг и социальная инженерия", "Модуль 2", 1, "published", "2023-04-16"),
            ("Сетевая безопасность", "Модуль 3", 2, "published", "2023-04-15"),
        ],
    )


_COURSE_STATUS_LABELS = {
    "published": "Опубликован",
    "draft": "Черновик",
    "pending": "На проверке",
}


def _format_db_date(value: str | None) -> str:
    if not value:
        return "—"
    parts = value[:10].split("-")
    if len(parts) == 3:
        return f"{parts[2]}/{parts[1]}/{parts[0]}"
    return value[:10]


def _display_name_from_email(email: str) -> str:
    local = email.split("@", 1)[0]
    return local.replace(".", " ").replace("_", " ").strip().title() or email


def _initials_from_email(email: str) -> str:
    local = email.split("@", 1)[0]
    letters = "".join(ch for ch in local if ch.isalnum())
    return (letters[:2] or "??").upper()


def _user_status(progress: int) -> tuple[str, str]:
    if progress <= 0:
        return "inactive", "Неактивен"
    if progress < 30:
        return "pending", "Ожидает"
    return "active", "Активен"


def _fetch_admin_users(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT u.id, u.email, u.created_at,
               COALESCE(s.progress_percent, 0) AS progress
        FROM users u
        LEFT JOIN dashboard_stats s ON s.user_id = u.id
        ORDER BY u.id ASC
        """
    ).fetchall()
    users: list[dict[str, Any]] = []
    for row in rows:
        progress = int(row["progress"])
        status, status_label = _user_status(progress)
        email = str(row["email"])
        users.append(
            {
                "id": int(row["id"]),
                "name": _display_name_from_email(email),
                "initials": _initials_from_email(email),
                "email": email,
                "registered_at": _format_db_date(str(row["created_at"])),
                "status": status,
                "status_label": status_label,
                "progress": progress,
            }
        )
    return users


def _fetch_admin_courses(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT id, title, module, lessons_count, status, updated_at
        FROM courses
        ORDER BY id ASC
        """
    ).fetchall()
    courses: list[dict[str, Any]] = []
    for row in rows:
        status = str(row["status"])
        courses.append(
            {
                "id": int(row["id"]),
                "title": str(row["title"]),
                "module": str(row["module"]),
                "lessons_count": int(row["lessons_count"]),
                "status": status,
                "status_label": _COURSE_STATUS_LABELS.get(status, status),
                "updated_at": _format_db_date(str(row["updated_at"])),
            }
        )
    return courses


def _get_current_user() -> User | None:
    user_id = session.get("user_id")
    if not user_id:
        return None
    with _connect_db() as conn:
        row = conn.execute("SELECT id, email FROM users WHERE id = ?", (user_id,)).fetchone()
        if not row:
            session.pop("user_id", None)
            return None
        return User(id=int(row["id"]), email=str(row["email"]))


def _login_required() -> User:
    user = _get_current_user()
    if not user:
        return abort(401)
    return user


@app.route("/", methods=["GET", "POST"])
def registration():
    # GET shows the form. POST creates the user.
    if request.method == "POST":
        email = (request.form.get("email") or "").strip().lower()
        password = request.form.get("password") or ""
        if not email or not password:
            return render_template("registration.html", error="Введите почту и пароль.")

        password_hash = generate_password_hash(password)
        try:
            with _connect_db() as conn:
                cur = conn.execute(
                    "INSERT INTO users (email, password_hash) VALUES (?, ?)",
                    (email, password_hash),
                )
                user_id = int(cur.lastrowid)
                _seed_user_data(conn, user_id)
        except sqlite3.IntegrityError:
            return render_template("registration.html", error="Пользователь с такой почтой уже существует.")

        session["user_id"] = user_id
        return redirect(url_for("dashboard"))

    return render_template("registration.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = (request.form.get("email") or "").strip().lower()
        password = request.form.get("password") or ""
        if not email or not password:
            return render_template("login.html", error="Введите почту и пароль.")

        with _connect_db() as conn:
            row = conn.execute(
                "SELECT id, password_hash FROM users WHERE email = ?",
                (email,),
            ).fetchone()
            if not row or not check_password_hash(row["password_hash"], password):
                return render_template("login.html", error="Неверная почта или пароль.")

            session["user_id"] = int(row["id"])
        return redirect(url_for("dashboard"))

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.pop("user_id", None)
    return redirect(url_for("login"))


@app.route("/dashboard")
def dashboard():
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    def clamp_0_100(v: Any) -> int:
        try:
            iv = int(v)
        except (TypeError, ValueError):
            iv = 0
        if iv < 0:
            return 0
        if iv > 100:
            return 100
        return iv

    with _connect_db() as conn:
        stats = conn.execute(
            "SELECT progress_percent, xp, topics_done, sections_done FROM dashboard_stats WHERE user_id = ?",
            (user.id,),
        ).fetchone()
        achievements = conn.execute(
            "SELECT amount, label FROM achievements WHERE user_id = ? ORDER BY sort_order ASC, id ASC",
            (user.id,),
        ).fetchall()
        history = conn.execute(
            "SELECT title, section, max_points, best_result FROM test_history WHERE user_id = ? ORDER BY id DESC LIMIT 10",
            (user.id,),
        ).fetchall()

    return render_template(
        "dashboard.html",
        user=user,
        active_nav="dashboard",
        stats=(
            {
                "progress_percent": int(stats["progress_percent"]) if stats else 0,
                "xp": int(stats["xp"]) if stats else 0,
                "topics_done": int(stats["topics_done"]) if stats else 0,
                "sections_done": int(stats["sections_done"]) if stats else 0,
                # Values used for visual progress bars (0..100)
                "progress_percent_clamped": clamp_0_100(stats["progress_percent"]) if stats else 0,
                "xp_clamped": clamp_0_100(stats["xp"]) if stats else 0,
                "topics_done_clamped": clamp_0_100(stats["topics_done"]) if stats else 0,
                "sections_done_clamped": clamp_0_100(stats["sections_done"]) if stats else 0,
            }
        ),
        achievements=[dict(r) for r in achievements],
        history=[dict(r) for r in history],
    )


@app.route("/admin")
def admin_panel():
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        users = _fetch_admin_users(conn)
        courses = _fetch_admin_courses(conn)

    return render_template(
        "admin.html",
        user=user,
        active_nav="admin",
        users=users,
        courses=courses,
    )


if __name__ == "__main__":
    _init_db()
    app.run(debug=True)
