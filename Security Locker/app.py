from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from flask import Flask, Response, abort, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash, generate_password_hash

from services.certificate_service import build_certificate_html, get_or_create_certificate
from services.course_service import get_course_modules, get_lesson_material, init_course_schema, mark_lesson_viewed
from services.test_service import get_default_test, get_test_question, get_test_result, init_test_schema, submit_test_result
from services.achievement_service import ACHIEVEMENTS_DEFINITIONS, check_and_award_achievements, get_achievement_progress, get_user_achievements

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
                amount INTEGER NOT NULL DEFAULT 0,
                label TEXT NOT NULL,
                achievement_key TEXT,
                description TEXT DEFAULT '',
                icon TEXT DEFAULT '',
                unlocked_at TEXT,
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

            CREATE TABLE IF NOT EXISTS tests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                course_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                passing_score INTEGER NOT NULL,
                FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS questions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                lesson_id INTEGER NOT NULL,
                question_text TEXT NOT NULL,
                explanation TEXT NOT NULL,
                FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS answers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                question_id INTEGER NOT NULL,
                answer_text TEXT NOT NULL,
                is_correct BOOLEAN NOT NULL DEFAULT FALSE,
                FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS user_answers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                test_history_id INTEGER NOT NULL,
                question_id INTEGER NOT NULL,
                answer_id INTEGER NOT NULL,
                is_correct BOOLEAN NOT NULL,
                FOREIGN KEY (test_history_id) REFERENCES test_history(id) ON DELETE CASCADE,
                FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
                FOREIGN KEY (answer_id) REFERENCES answers(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS certificates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                course_id INTEGER NOT NULL,
                test_history_id INTEGER NOT NULL DEFAULT 0,
                certificate_number TEXT NOT NULL,
                issued_at TEXT NOT NULL,
                pdf_path TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
                FOREIGN KEY (test_history_id) REFERENCES test_history(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS password_reset_tokens (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                token TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                expires_at TEXT NOT NULL DEFAULT 'draft',
                used BOOLEAN NOT NULL DEFAULT FALSE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
            """
        )
        init_course_schema(conn)
        init_test_schema(conn)
        _seed_courses(conn)


def _seed_user_data(conn: sqlite3.Connection, user_id: int) -> None:
    _ensure_achievement_columns(conn)
    conn.execute(
        "INSERT OR IGNORE INTO dashboard_stats (user_id, progress_percent, xp, topics_done, sections_done) VALUES (?, 0, 0, 0, 0)",
        (user_id,),
    )
    # Achievements (placeholders to match current UI)
    conn.executemany(
        "INSERT INTO achievements (user_id, achievement_key, label, description, icon, sort_order) VALUES (?, ?, ?, ?, ?, ?)",
        [
            (user_id, a["key"], a["title"], a["description"], a["icon"], a["sort_order"])
            for a in ACHIEVEMENTS_DEFINITIONS
        ],
    )
    # Test history (placeholders to match current table)
    conn.executemany(
        "INSERT INTO test_history (user_id, title, section, max_points, best_result) VALUES (?, ?, ?, ?, ?)",
        [
            (user_id, a["title"], a["section"], a["max_points"], a["best_result"])
            for a in TEST_HISTORY_DEFINITIONS
        ],
    )


def _ensure_achievement_columns(conn: sqlite3.Connection) -> None:
    columns = {str(col["name"]) for col in conn.execute("PRAGMA table_info(achievements)").fetchall()}
    if "achievement_key" not in columns:
        conn.execute("ALTER TABLE achievements ADD COLUMN achievement_key TEXT")
    if "description" not in columns:
        conn.execute("ALTER TABLE achievements ADD COLUMN description TEXT DEFAULT ''")
    if "icon" not in columns:
        conn.execute("ALTER TABLE achievements ADD COLUMN icon TEXT DEFAULT ''")
    if "unlocked_at" not in columns:
        conn.execute("ALTER TABLE achievements ADD COLUMN unlocked_at TEXT")

    _migrate_achievements_data(conn)


def _migrate_achievements_data(conn: sqlite3.Connection) -> None:
    existing_achievements = conn.execute(
        "SELECT DISTINCT user_id FROM achievements WHERE achievement_key IS NULL LIMIT 1"
    ).fetchone()

    if not existing_achievements:
        return

    conn.execute("DELETE FROM achievements WHERE achievement_key IS NULL")

    users = conn.execute("SELECT id FROM users").fetchall()
    for user in users:
        user_id = int(user["id"])
        conn.executemany(
            "INSERT INTO achievements (user_id, achievement_key, label, description, icon, amount, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [
                (user_id, a["key"], a["title"], a["description"], a["icon"], 0, a["sort_order"])
                for a in ACHIEVEMENTS_DEFINITIONS
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


@app.before_request
def _ensure_db_initialized() -> None:
    if app.config.get("DB_INITIALIZED"):
        return
    _init_db()
    app.config["DB_INITIALIZED"] = True


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
        _ensure_achievement_columns(conn)
        stats = conn.execute(
            "SELECT progress_percent, xp, topics_done, sections_done FROM dashboard_stats WHERE user_id = ?",
            (user.id,),
        ).fetchone()
        all_achievements = get_user_achievements(conn, user.id)
        achievements_to_show = all_achievements[:2]
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
        achievements=achievements_to_show,
        history=[dict(r) for r in history],
    )


@app.route("/modules")
def modules():
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        course_modules = get_course_modules(conn, user.id)

    return render_template(
        "modules.html",
        user=user,
        active_nav="modules",
        modules=course_modules,
    )


@app.route("/lesson/<int:lesson_id>")
def lesson_material_page(lesson_id: int):
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        mark_lesson_viewed(conn, user.id, lesson_id)
        check_and_award_achievements(conn, user.id)
        lesson = get_lesson_material(conn, lesson_id)

    if lesson is None:
        abort(404)

    return render_template(
        "lesson_material.html",
        user=user,
        lesson=lesson,
        active_nav="modules",
    )


@app.route("/achievements")
def achievements_page():
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        _ensure_achievement_columns(conn)
        all_achievements = get_user_achievements(conn, user.id)
        achievement_progress = {}
        for achievement in all_achievements:
            progress = get_achievement_progress(conn, user.id, achievement.get("achievement_key"))
            if progress:
                achievement_progress[achievement.get("achievement_key")] = progress

    return render_template(
        "achievements.html",
        user=user,
        active_nav="achievements",
        achievements=all_achievements,
        achievement_progress=achievement_progress,
    )


@app.post("/admin/users/<int:user_id>/delete")
def admin_delete_user(user_id: int):
    current_user = _get_current_user()

    if not current_user or not current_user.is_admin:
        abort(403)

    if current_user.id == user_id:
        flash("Нельзя удалить собственную учетную запись.", "error")
        return redirect(url_for("admin_panel"))

    with _connect_db() as conn:
        conn.execute(
            "DELETE FROM users WHERE id = ? ON DELETE CASCADE",
            (user_id,)
        )
        conn.commit()

    flash("Пользователь удалён.", "success")

    return redirect(url_for("admin_panel"))


@app.route("/tests")
def tests():
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        course_modules = get_course_modules(conn, user.id)

    return render_template(
        "tests.html",
        user=user,
        active_nav="tests",
        modules=course_modules,
    )


@app.route("/tests/start", methods=["GET", "POST"])
@app.route("/test_question_screen", methods=["GET", "POST"])
def test_question_screen():
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    if request.method == "POST":
        test_id = int(request.form.get("test_id") or 0)
        question_index = int(request.form.get("question_index") or 0)
        question_id = request.form.get("question_id") or ""
        answer_id = int(request.form.get("answer_id") or 0)

        answers = dict(session.get("test_answers") or {})
        if question_id and answer_id:
            answers[str(question_id)] = answer_id
            session["test_answers"] = answers

        with _connect_db() as conn:
            test = get_default_test(conn)
            if not test or int(test["id"]) != test_id:
                abort(404)

            next_index = question_index + 1
            if next_index < int(test["question_count"]):
                return redirect(url_for("test_question_screen", question=next_index))

            result = submit_test_result(conn, user.id, test_id, answers)
            check_and_award_achievements(conn, user.id)
            session.pop("test_answers", None)

        return redirect(url_for("test_result", history_id=result["history_id"]))

    question_index = int(request.args.get("question") or 0)
    if "question" not in request.args:
        session["test_answers"] = {}

    with _connect_db() as conn:
        test = get_default_test(conn)
        if not test:
            abort(404)
        question = get_test_question(conn, int(test["id"]), question_index)
        if not question:
            return redirect(url_for("test_question_screen"))

    return render_template(
        "test_question.html",
        user=user,
        active_nav="tests",
        test=test,
        question=question,
    )


@app.route("/tests/result/<int:history_id>")
def test_result(history_id: int):
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        result = get_test_result(conn, user.id, history_id)
        if not result:
            abort(404)

    return render_template(
        "test_result.html",
        user=user,
        active_nav="tests",
        result=result,
    )


@app.route("/certificate/<int:history_id>")
def download_certificate(history_id: int):
    user = _get_current_user()
    if not user:
        return redirect(url_for("login"))

    with _connect_db() as conn:
        result = get_test_result(conn, user.id, history_id)
        if not result:
            abort(404)
        if not result["passed"]:
            abort(403)

        certificate = get_or_create_certificate(conn, user.id, int(result["course_id"]), history_id)
        certificate_html = build_certificate_html(
            certificate_number=certificate["certificate_number"],
            issued_at=certificate["issued_at"],
            user_email=user.email,
            course_title=str(result["course_title"]),
            score=int(result["score"]),
            total=int(result["total"]),
        )

    filename = certificate["pdf_path"]
    return Response(
        certificate_html,
        mimetype="text/html",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
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
