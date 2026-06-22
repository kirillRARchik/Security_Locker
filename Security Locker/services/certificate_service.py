from __future__ import annotations

import html
import sqlite3
from datetime import datetime


def get_or_create_certificate(
    conn: sqlite3.Connection,
    user_id: int,
    course_id: int,
    test_history_id: int,
) -> dict[str, str]:
    existing = conn.execute(
        """
        SELECT certificate_number, issued_at, pdf_path
        FROM certificates
        WHERE user_id = ? AND course_id = ? AND test_history_id = ?
        """,
        (user_id, course_id, test_history_id),
    ).fetchone()
    if existing:
        return {
            "certificate_number": str(existing["certificate_number"]),
            "issued_at": str(existing["issued_at"]),
            "pdf_path": str(existing["pdf_path"]),
        }

    issued_at = datetime.utcnow().strftime("%Y-%m-%d")
    certificate_number = f"SL-{user_id:04d}-{test_history_id:05d}"
    pdf_path = f"certificate-{certificate_number}.html"
    conn.execute(
        """
        INSERT INTO certificates (user_id, course_id, test_history_id, certificate_number, issued_at, pdf_path)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (user_id, course_id, test_history_id, certificate_number, issued_at, pdf_path),
    )
    return {
        "certificate_number": certificate_number,
        "issued_at": issued_at,
        "pdf_path": pdf_path,
    }


def build_certificate_html(
    *,
    certificate_number: str,
    issued_at: str,
    user_email: str,
    course_title: str,
    score: int,
    total: int,
) -> str:
    safe_number = html.escape(certificate_number)
    safe_date = html.escape(issued_at)
    safe_email = html.escape(user_email)
    safe_course = html.escape(course_title)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Security Locker Certificate</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            background: #f3f6fb;
            color: #172033;
            padding: 48px;
        }}

        .certificate {{
            max-width: 860px;
            margin: 0 auto;
            background: #fff;
            border: 8px solid #2a84ff;
            padding: 56px;
            text-align: center;
        }}

        h1 {{
            margin: 0 0 18px;
            font-size: 42px;
        }}

        .subtitle {{
            color: #6b7280;
            font-size: 18px;
            margin-bottom: 40px;
        }}

        .recipient {{
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 20px;
        }}

        .course {{
            font-size: 22px;
            margin-bottom: 36px;
        }}

        .meta {{
            display: flex;
            justify-content: space-between;
            gap: 20px;
            border-top: 1px solid #e5ecf7;
            padding-top: 24px;
            color: #4b5563;
            font-size: 14px;
        }}
    </style>
</head>
<body>
    <main class="certificate">
        <h1>Certificate of Completion</h1>
        <p class="subtitle">Security Locker confirms successful test completion</p>
        <div class="recipient">{safe_email}</div>
        <div class="course">{safe_course}</div>
        <p>Score: {score} / {total}</p>
        <div class="meta">
            <span>Certificate: {safe_number}</span>
            <span>Issued: {safe_date}</span>
        </div>
    </main>
</body>
</html>"""
