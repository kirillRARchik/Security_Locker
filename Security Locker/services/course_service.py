from __future__ import annotations

import sqlite3
from typing import Any


COURSE_SEED_DATA = [
    {
        "title": "Basic of English Language",
        "module": "Module 1",
        "accent": "violet",
        "lessons": [
            ("Introduction to Grammar", 10),
            ("Parts of Speech", 15),
            ("Sentence Structure", 12),
            ("Punctuation Rules", 8),
        ],
    },
    {
        "title": "Introduction the web development",
        "module": "Module 2",
        "accent": "blue",
        "lessons": [
            ("HTML Basics", 14),
            ("CSS Layout", 16),
            ("JavaScript Introduction", 20),
        ],
    },
    {
        "title": "Basic data-structure and algorithm",
        "module": "Module 3",
        "accent": "violet",
        "lessons": [
            ("Arrays and Lists", 11),
            ("Stacks and Queues", 15),
            ("Sorting Basics", 18),
        ],
    },
    {
        "title": "Lorem ipsum codor le hala madrid",
        "module": "Module 4",
        "accent": "blue",
        "lessons": [
            ("Fundamentals of Electronics", 12),
            ("PCB Boards", 14),
            ("Schematic", 10),
        ],
    },
]


def init_course_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            module TEXT NOT NULL,
            lessons_count INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'draft',
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS lessons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL DEFAULT '',
            xp_for_completion INTEGER NOT NULL DEFAULT 0,
            course_id INTEGER NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS lesson_progress (
            user_id INTEGER NOT NULL,
            lesson_id INTEGER NOT NULL,
            viewed_at TEXT NOT NULL DEFAULT (datetime('now')),
            PRIMARY KEY (user_id, lesson_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
        );
        """
    )
    _ensure_lesson_columns(conn)
    _seed_courses_and_lessons(conn)


def get_course_modules(conn: sqlite3.Connection, user_id: int) -> list[dict[str, Any]]:
    courses = conn.execute(
        """
        SELECT id, title, module
        FROM courses
        ORDER BY id ASC
        """
    ).fetchall()

    modules: list[dict[str, Any]] = []
    for index, course in enumerate(courses):
        lessons = conn.execute(
            """
            SELECT l.id, l.title, l.duration_minutes, l.xp_for_completion,
                   CASE WHEN lp.lesson_id IS NULL THEN 0 ELSE 1 END AS is_viewed
            FROM lessons l
            LEFT JOIN lesson_progress lp
                ON lp.lesson_id = l.id AND lp.user_id = ?
            WHERE l.course_id = ?
            ORDER BY l.sort_order ASC, l.id ASC
            """,
            (user_id, int(course["id"])),
        ).fetchall()

        lesson_items = [
            {
                "id": int(row["id"]),
                "title": str(row["title"]),
                "duration_minutes": int(row["duration_minutes"]),
                "xp_for_completion": int(row["xp_for_completion"]),
                "is_viewed": bool(row["is_viewed"]),
            }
            for row in lessons
        ]
        viewed_count = sum(1 for lesson in lesson_items if lesson["is_viewed"])
        lessons_count = len(lesson_items)
        progress_percent = round((viewed_count / lessons_count) * 100) if lessons_count else 0

        modules.append(
            {
                "id": int(course["id"]),
                "title": str(course["title"]),
                "module": str(course["module"]),
                "accent": COURSE_SEED_DATA[index % len(COURSE_SEED_DATA)]["accent"],
                "lessons_count": lessons_count,
                "viewed_count": viewed_count,
                "progress_percent": progress_percent,
                "is_open": index == 0,
                "lessons": lesson_items,
            }
        )

    return modules

def get_lesson_material(conn: sqlite3.Connection, lesson_id: int) -> dict[str, Any] | None:
    lesson = conn.execute(
        """
        SELECT l.id, l.title, l.content, l.duration_minutes, l.xp_for_completion,
               c.id AS course_id, c.title AS course_title, c.module AS course_module
        FROM lessons l
        JOIN courses c ON c.id = l.course_id
        WHERE l.id = ?
        """,
        (lesson_id,),
    ).fetchone()

    if lesson is None:
        return None

    return {
        "id": int(lesson["id"]),
        "title": str(lesson["title"]),
        "content": str(lesson["content"]),
        "duration_minutes": int(lesson["duration_minutes"]),
        "xp_for_completion": int(lesson["xp_for_completion"]),
        "course": {
            "id": int(lesson["course_id"]),
            "title": str(lesson["course_title"]),
            "module": str(lesson["course_module"]),
        },
    }

def mark_lesson_viewed(conn: sqlite3.Connection, user_id: int, lesson_id: int) -> None:
    conn.execute(
        """
        INSERT OR IGNORE INTO lesson_progress (user_id, lesson_id)
        SELECT ?, id FROM lessons WHERE id = ?
        """,
        (user_id, lesson_id),
    )


def _ensure_lesson_columns(conn: sqlite3.Connection) -> None:
    columns = {str(column["name"]) for column in conn.execute("PRAGMA table_info(lessons)").fetchall()}
    if "duration_minutes" not in columns:
        conn.execute("ALTER TABLE lessons ADD COLUMN duration_minutes INTEGER NOT NULL DEFAULT 0")
    if "xp_for_completion" not in columns:
        conn.execute("ALTER TABLE lessons ADD COLUMN xp_for_completion INTEGER NOT NULL DEFAULT 0")


def _seed_courses_and_lessons(conn: sqlite3.Connection) -> None:
    lesson_count = conn.execute("SELECT COUNT(*) AS c FROM lessons").fetchone()
    if lesson_count and int(lesson_count["c"]) > 0:
        return

    for course_index, course in enumerate(COURSE_SEED_DATA, start=1):
        row = conn.execute(
            "SELECT id FROM courses WHERE title = ?",
            (course["title"],),
        ).fetchone()
        if row:
            course_id = int(row["id"])
            conn.execute(
                "UPDATE courses SET lessons_count = ?, status = 'published' WHERE id = ?",
                (len(course["lessons"]), course_id),
            )
        else:
            cursor = conn.execute(
                """
                INSERT INTO courses (title, module, lessons_count, status)
                VALUES (?, ?, ?, 'published')
                """,
                (course["title"], course["module"], len(course["lessons"])),
            )
            course_id = int(cursor.lastrowid)

        conn.executemany(
            """
            INSERT INTO lessons (title, content, duration_minutes, xp_for_completion, course_id, sort_order)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    lesson_title,
                    f"Material for {lesson_title}.",
                    duration_minutes,
                    duration_minutes,
                    course_id,
                    lesson_index,
                )
                for lesson_index, (lesson_title, duration_minutes) in enumerate(course["lessons"], start=1)
            ],
        )
