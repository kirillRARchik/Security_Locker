from __future__ import annotations

import sqlite3
from datetime import datetime
from typing import Any

ACHIEVEMENTS_DEFINITIONS = [
    {
        "key": "first_module",
        "title": "Всегда сложно",
        "description": "Завершите первый модуль",
        "icon": "🎯",
        "sort_order": 1,
    },
    {
        "key": "two_modules",
        "title": "Вооружён",
        "description": "Завершите первые два модуля",
        "icon": "💪",
        "sort_order": 2,
    },
    {
        "key": "first_test",
        "title": "Первый рубеж",
        "description": "Пройдите первый тест",
        "icon": "🏁",
        "sort_order": 3,
    },
    {
        "key": "perfect_score",
        "title": "Топ скорер",
        "description": "Получите 100% за тест",
        "icon": "🌟",
        "sort_order": 4,
    },
    {
        "key": "xp_100",
        "title": "Значимый опыт",
        "description": "Наберите 100 XP",
        "icon": "📚",
        "sort_order": 5,
    },
    {
        "key": "module_2",
        "title": "Приватен в Интернете",
        "description": "Завершите модуль 2",
        "icon": "🔒",
        "sort_order": 6,
    },
    {
        "key": "module_3",
        "title": "Безопасное общение",
        "description": "Завершите модуль 3",
        "icon": "💬",
        "sort_order": 7,
    },
    {
        "key": "module_4",
        "title": "Белый хакер",
        "description": "Завершите модуль 4",
        "icon": "⚡",
        "sort_order": 8,
    },
    {
        "key": "all_modules",
        "title": "Подготовлен",
        "description": "Завершите все модули",
        "icon": "🏆",
        "sort_order": 9,
    },
]


def get_user_achievements(conn: sqlite3.Connection, user_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT id, achievement_key, label, description, icon, unlocked_at, sort_order
        FROM achievements
        WHERE user_id = ?
        ORDER BY sort_order ASC
        """,
        (user_id,),
    ).fetchall()

    return [dict(row) for row in rows]


def get_achievement_progress(
    conn: sqlite3.Connection, user_id: int, achievement_key: str
) -> dict[str, Any] | None:
    if achievement_key == "first_module":
        count = _get_completed_modules_count(conn, user_id)
        return {"current": count, "total": 1, "text": f"{count} из 1 модуля"}
    elif achievement_key == "two_modules":
        count = _get_completed_modules_count(conn, user_id)
        return {"current": count, "total": 2, "text": f"{count} из 2 модулей"}
    elif achievement_key == "module_2":
        count = _get_completed_modules_count(conn, user_id, course_id=2)
        return {"current": count, "total": 1, "text": "Завершите модуль 2"}
    elif achievement_key == "module_3":
        count = _get_completed_modules_count(conn, user_id, course_id=3)
        return {"current": count, "total": 1, "text": "Завершите модуль 3"}
    elif achievement_key == "module_4":
        count = _get_completed_modules_count(conn, user_id, course_id=4)
        return {"current": count, "total": 1, "text": "Завершите модуль 4"}
    elif achievement_key == "all_modules":
        count = _get_completed_modules_count(conn, user_id)
        return {"current": count, "total": 4, "text": f"{count} из 4 модулей"}
    elif achievement_key == "first_test":
        count = _get_passed_tests_count(conn, user_id)
        return {"current": count, "total": 1, "text": "Пройдите первый тест"}
    elif achievement_key == "perfect_score":
        has_perfect = _has_perfect_score_test(conn, user_id)
        return {"current": 1 if has_perfect else 0, "total": 1, "text": "Получите 100% за тест"}
    elif achievement_key == "xp_100":
        xp = _get_total_xp(conn, user_id)
        return {"current": xp, "total": 100, "text": f"{xp} из 100 XP"}

    return None


def check_and_award_achievements(conn: sqlite3.Connection, user_id: int) -> None:
    for achievement in ACHIEVEMENTS_DEFINITIONS:
        key = achievement["key"]
        existing = conn.execute(
            "SELECT unlocked_at FROM achievements WHERE user_id = ? AND achievement_key = ?",
            (user_id, key),
        ).fetchone()

        if existing and existing["unlocked_at"]:
            continue

        is_unlocked = False
        if key == "first_module":
            is_unlocked = _get_completed_modules_count(conn, user_id) >= 1
        elif key == "two_modules":
            is_unlocked = _get_completed_modules_count(conn, user_id) >= 2
        elif key == "module_2":
            is_unlocked = _get_completed_modules_count(conn, user_id, course_id=2) >= 1
        elif key == "module_3":
            is_unlocked = _get_completed_modules_count(conn, user_id, course_id=3) >= 1
        elif key == "module_4":
            is_unlocked = _get_completed_modules_count(conn, user_id, course_id=4) >= 1
        elif key == "all_modules":
            is_unlocked = _get_completed_modules_count(conn, user_id) >= 4
        elif key == "first_test":
            is_unlocked = _get_passed_tests_count(conn, user_id) >= 1
        elif key == "perfect_score":
            is_unlocked = _has_perfect_score_test(conn, user_id)
        elif key == "xp_100":
            is_unlocked = _get_total_xp(conn, user_id) >= 100

        if is_unlocked:
            now = datetime.now().isoformat()
            conn.execute(
                "UPDATE achievements SET unlocked_at = ? WHERE user_id = ? AND achievement_key = ?",
                (now, user_id, key),
            )


def _get_completed_modules_count(
    conn: sqlite3.Connection, user_id: int, course_id: int | None = None
) -> int:
    if course_id:
        row = conn.execute(
            """
            SELECT COUNT(DISTINCT l.id) as total
            FROM lessons l
            WHERE l.course_id = ?
            """,
            (course_id,),
        ).fetchone()
        total_lessons = int(row["total"]) if row else 0

        row = conn.execute(
            """
            SELECT COUNT(DISTINCT lp.lesson_id) as completed
            FROM lesson_progress lp
            JOIN lessons l ON l.id = lp.lesson_id
            WHERE lp.user_id = ? AND l.course_id = ?
            """,
            (user_id, course_id),
        ).fetchone()
        completed = int(row["completed"]) if row else 0

        return 1 if completed == total_lessons and total_lessons > 0 else 0

    rows = conn.execute(
        """
        SELECT l.course_id,
               COUNT(l.id) as total_lessons,
               COUNT(lp.lesson_id) as completed_lessons
        FROM lessons l
        LEFT JOIN lesson_progress lp
            ON lp.lesson_id = l.id AND lp.user_id = ?
        GROUP BY l.course_id
        """,
        (user_id,),
    ).fetchall()

    completed_modules = 0
    for row in rows:
        total = int(row["total_lessons"])
        completed = int(row["completed_lessons"])
        if total > 0 and completed == total:
            completed_modules += 1

    return completed_modules


def _get_passed_tests_count(conn: sqlite3.Connection, user_id: int) -> int:
    row = conn.execute(
        "SELECT COUNT(*) as count FROM test_history WHERE user_id = ? AND passed = 1",
        (user_id,),
    ).fetchone()
    return int(row["count"]) if row else 0


def _has_perfect_score_test(conn: sqlite3.Connection, user_id: int) -> bool:
    row = conn.execute(
        """
        SELECT COUNT(*) as count
        FROM test_history
        WHERE user_id = ?
              AND score = max_points
              AND score > 0
        """,
        (user_id,),
    ).fetchone()
    return int(row["count"]) > 0 if row else False


def _get_total_xp(conn: sqlite3.Connection, user_id: int) -> int:
    row = conn.execute(
        """
        SELECT COALESCE(SUM(l.xp_for_completion), 0) as total_xp
        FROM lesson_progress lp
        JOIN lessons l ON l.id = lp.lesson_id
        WHERE lp.user_id = ?
        """,
        (user_id,),
    ).fetchone()
    return int(row["total_xp"]) if row else 0
