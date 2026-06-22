from __future__ import annotations

import sqlite3
from typing import Any


TEST_SEED = {
    "title": "Workplace Readiness Test",
    "passing_score": 4,
    "questions": [
        {
            "text": "What is the safest way to store a work password?",
            "explanation": "A password manager keeps passwords unique, encrypted, and easier to rotate.",
            "answers": [
                ("In a password manager.", True),
                ("In a public note on the desktop.", False),
                ("In a chat with yourself.", False),
                ("On a sticky note near the monitor.", False),
            ],
        },
        {
            "text": "What is your ideal workplace?",
            "explanation": "A structured workplace with clear policies reduces security mistakes.",
            "answers": [
                ("A place where people don't question my authority.", False),
                ("Wherever my best friends are, that's where I want to be.", False),
                ("One where everyone pushes themselves to do their best every single day.", False),
                ("One that's organized, structured and has workplace policies set.", True),
                ("A place where everyone knows I'm the boss.", False),
                ("A place where I'm the CEO.", False),
            ],
        },
        {
            "text": "What should you check before opening an email attachment?",
            "explanation": "Sender identity, context, and file type help identify phishing attempts.",
            "answers": [
                ("Only the file name.", False),
                ("The sender, context, and whether the file was expected.", True),
                ("Whether the email sounds urgent.", False),
                ("The attachment icon color.", False),
            ],
        },
        {
            "text": "Which network is safer for sensitive work?",
            "explanation": "Trusted networks and VPNs reduce exposure when working with sensitive data.",
            "answers": [
                ("Any open public Wi-Fi.", False),
                ("A trusted network, preferably with VPN when required.", True),
                ("A network with the funniest name.", False),
                ("The first network without a password.", False),
            ],
        },
        {
            "text": "What should you do after suspecting account compromise?",
            "explanation": "Fast reporting and credential rotation limit damage.",
            "answers": [
                ("Ignore it unless it happens again.", False),
                ("Report it and change credentials using the approved process.", True),
                ("Delete browser history.", False),
                ("Ask coworkers to stop emailing you.", False),
            ],
        },
        {
            "text": "What makes multi-factor authentication useful?",
            "explanation": "MFA adds a second proof, so a stolen password alone is less useful.",
            "answers": [
                ("It replaces all security training.", False),
                ("It makes every password public.", False),
                ("It adds another proof of identity beyond the password.", True),
                ("It makes login pages load faster.", False),
            ],
        },
    ],
}


def init_test_schema(conn: sqlite3.Connection) -> None:
    _ensure_test_history_result_columns(conn)
    _seed_default_test(conn)


def get_default_test(conn: sqlite3.Connection) -> dict[str, Any] | None:
    row = conn.execute(
        """
        SELECT t.id, t.title, t.passing_score, c.title AS course_title
        FROM tests t
        JOIN courses c ON c.id = t.course_id
        ORDER BY t.id ASC
        LIMIT 1
        """
    ).fetchone()
    if not row:
        return None

    question_count = conn.execute(
        """
        SELECT COUNT(*) AS c
        FROM questions q
        JOIN lessons l ON l.id = q.lesson_id
        WHERE l.course_id = (
            SELECT course_id FROM tests WHERE id = ?
        )
        """,
        (int(row["id"]),),
    ).fetchone()

    return {
        "id": int(row["id"]),
        "title": str(row["title"]),
        "course_title": str(row["course_title"]),
        "passing_score": int(row["passing_score"]),
        "question_count": int(question_count["c"]) if question_count else 0,
    }


def get_test_question(conn: sqlite3.Connection, test_id: int, index: int) -> dict[str, Any] | None:
    questions = _get_test_questions(conn, test_id)
    if index < 0 or index >= len(questions):
        return None

    question = questions[index]
    answers = conn.execute(
        """
        SELECT id, answer_text
        FROM answers
        WHERE question_id = ?
        ORDER BY id ASC
        """,
        (question["id"],),
    ).fetchall()

    return {
        "id": int(question["id"]),
        "text": str(question["question_text"]),
        "number": index + 1,
        "total": len(questions),
        "answers": [{"id": int(row["id"]), "text": str(row["answer_text"])} for row in answers],
    }


def submit_test_result(
    conn: sqlite3.Connection,
    user_id: int,
    test_id: int,
    selected_answers: dict[str, int],
) -> dict[str, Any]:
    test = conn.execute(
        """
        SELECT t.id, t.title, t.passing_score, t.course_id, c.title AS course_title
        FROM tests t
        JOIN courses c ON c.id = t.course_id
        WHERE t.id = ?
        """,
        (test_id,),
    ).fetchone()
    if not test:
        raise ValueError("Test not found.")

    questions = _get_test_questions(conn, test_id)
    question_ids = [int(row["id"]) for row in questions]
    correct_answers = conn.execute(
        """
        SELECT question_id, id
        FROM answers
        WHERE is_correct = 1 AND question_id IN ({})
        """.format(",".join("?" for _ in question_ids)),
        question_ids,
    ).fetchall()
    correct_by_question = {int(row["question_id"]): int(row["id"]) for row in correct_answers}

    score = 0
    answer_rows: list[tuple[int, int, int, bool]] = []
    for question_id in question_ids:
        answer_id = int(selected_answers.get(str(question_id), 0))
        is_correct = answer_id == correct_by_question.get(question_id)
        if is_correct:
            score += 1
        if answer_id:
            answer_rows.append((question_id, answer_id, answer_id, is_correct))

    total = len(question_ids)
    passing_score = int(test["passing_score"])
    passed = score >= passing_score

    cursor = conn.execute(
        """
        INSERT INTO test_history (user_id, title, section, max_points, best_result, test_id, score, passed)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            str(test["title"]),
            str(test["course_title"]),
            total,
            score,
            test_id,
            score,
            int(passed),
        ),
    )
    history_id = int(cursor.lastrowid)

    conn.executemany(
        """
        INSERT INTO user_answers (test_history_id, question_id, answer_id, is_correct)
        VALUES (?, ?, ?, ?)
        """,
        [(history_id, question_id, answer_id, int(is_correct)) for question_id, answer_id, _, is_correct in answer_rows],
    )

    return {
        "history_id": history_id,
        "test_id": test_id,
        "title": str(test["title"]),
        "course_title": str(test["course_title"]),
        "course_id": int(test["course_id"]),
        "score": score,
        "total": total,
        "passing_score": passing_score,
        "passed": passed,
    }


def get_test_result(conn: sqlite3.Connection, user_id: int, history_id: int) -> dict[str, Any] | None:
    row = conn.execute(
        """
        SELECT th.id, th.title, th.section, th.max_points, th.best_result,
               COALESCE(th.score, th.best_result) AS score,
               COALESCE(th.passed, 0) AS passed,
               COALESCE(th.test_id, 0) AS test_id,
               COALESCE(t.passing_score, th.max_points) AS passing_score,
               COALESCE(t.course_id, 0) AS course_id
        FROM test_history th
        LEFT JOIN tests t ON t.id = th.test_id
        WHERE th.id = ? AND th.user_id = ?
        """,
        (history_id, user_id),
    ).fetchone()
    if not row:
        return None

    return {
        "history_id": int(row["id"]),
        "title": str(row["title"]),
        "course_title": str(row["section"]),
        "score": int(row["score"]),
        "total": int(row["max_points"]),
        "passing_score": int(row["passing_score"]),
        "passed": bool(row["passed"]),
        "test_id": int(row["test_id"]),
        "course_id": int(row["course_id"]),
    }


def _get_test_questions(conn: sqlite3.Connection, test_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        """
        SELECT q.id, q.question_text, q.explanation
        FROM questions q
        JOIN lessons l ON l.id = q.lesson_id
        JOIN tests t ON t.course_id = l.course_id
        WHERE t.id = ?
        ORDER BY q.id ASC
        """,
        (test_id,),
    ).fetchall()


def _ensure_test_history_result_columns(conn: sqlite3.Connection) -> None:
    columns = {str(column["name"]) for column in conn.execute("PRAGMA table_info(test_history)").fetchall()}
    if "test_id" not in columns:
        conn.execute("ALTER TABLE test_history ADD COLUMN test_id INTEGER NOT NULL DEFAULT 0")
    if "score" not in columns:
        conn.execute("ALTER TABLE test_history ADD COLUMN score INTEGER NOT NULL DEFAULT 0")
    if "passed" not in columns:
        conn.execute("ALTER TABLE test_history ADD COLUMN passed BOOLEAN NOT NULL DEFAULT FALSE")


def _seed_default_test(conn: sqlite3.Connection) -> None:
    existing = conn.execute("SELECT id FROM tests LIMIT 1").fetchone()
    if existing:
        return

    course = conn.execute(
        """
        SELECT c.id
        FROM courses c
        WHERE EXISTS (
            SELECT 1 FROM lessons l WHERE l.course_id = c.id
        )
        ORDER BY c.id ASC
        LIMIT 1
        """
    ).fetchone()
    if not course:
        return

    lesson = conn.execute(
        "SELECT id FROM lessons WHERE course_id = ? ORDER BY sort_order ASC, id ASC LIMIT 1",
        (int(course["id"]),),
    ).fetchone()
    if not lesson:
        return

    cursor = conn.execute(
        "INSERT INTO tests (course_id, title, passing_score) VALUES (?, ?, ?)",
        (int(course["id"]), TEST_SEED["title"], int(TEST_SEED["passing_score"])),
    )
    test_id = int(cursor.lastrowid)

    for question in TEST_SEED["questions"]:
        question_cursor = conn.execute(
            """
            INSERT INTO questions (lesson_id, question_text, explanation)
            VALUES (?, ?, ?)
            """,
            (int(lesson["id"]), question["text"], question["explanation"]),
        )
        question_id = int(question_cursor.lastrowid)
        conn.executemany(
            """
            INSERT INTO answers (question_id, answer_text, is_correct)
            VALUES (?, ?, ?)
            """,
            [(question_id, answer_text, int(is_correct)) for answer_text, is_correct in question["answers"]],
        )

    # Keep linters honest while making the seed test id explicit for future extension.
    _ = test_id
