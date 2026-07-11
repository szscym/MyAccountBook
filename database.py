import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), 'accountbook.db')


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_conn()
    c = conn.cursor()

    c.execute("""
        CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('income', 'expense'))
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
            amount REAL NOT NULL,
            category_id INTEGER,
            date TEXT NOT NULL,
            description TEXT DEFAULT '',
            created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
            FOREIGN KEY (category_id) REFERENCES categories(id)
        )
    """)

    conn.commit()
    _seed_categories(c)
    conn.close()


def _seed_categories(c):
    c.execute("SELECT COUNT(*) FROM categories")
    if c.fetchone()[0] > 0:
        return
    expense_cats = ['餐饮', '交通', '购物', '娱乐', '住房', '医疗', '教育', '通讯', '日用', '其他']
    income_cats = ['工资', '兼职', '投资', '红包', '其他']
    for name in expense_cats:
        c.execute("INSERT INTO categories (name, type) VALUES (?, 'expense')", (name,))
    for name in income_cats:
        c.execute("INSERT INTO categories (name, type) VALUES (?, 'income')", (name,))
    conn = c.connection
    conn.commit()


def add_transaction(t_type, amount, category_id, date, description=''):
    conn = get_conn()
    c = conn.cursor()
    c.execute(
        "INSERT INTO transactions (type, amount, category_id, date, description) VALUES (?, ?, ?, ?, ?)",
        (t_type, amount, category_id, date, description),
    )
    conn.commit()
    conn.close()


def get_summary():
    conn = get_conn()
    c = conn.cursor()
    c.execute("""
        SELECT
            COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0) AS total_income,
            COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0) AS total_expense
        FROM transactions
    """)
    row = dict(c.fetchone())
    conn.close()
    row['balance'] = row['total_income'] - row['total_expense']
    return row


def get_transactions(limit=50, offset=0):
    conn = get_conn()
    c = conn.cursor()
    c.execute("""
        SELECT t.id, t.type, t.amount, t.date, t.description,
               COALESCE(c.name, '未分类') AS category_name
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        ORDER BY t.date DESC, t.id DESC
        LIMIT ? OFFSET ?
    """, (limit, offset))
    rows = [dict(r) for r in c.fetchall()]
    conn.close()
    return rows


def get_categories(t_type):
    conn = get_conn()
    c = conn.cursor()
    c.execute("SELECT id, name FROM categories WHERE type = ?", (t_type,))
    rows = [dict(r) for r in c.fetchall()]
    conn.close()
    return rows


def delete_transaction(t_id):
    conn = get_conn()
    c = conn.cursor()
    c.execute("DELETE FROM transactions WHERE id = ?", (t_id,))
    conn.commit()
    conn.close()


def get_transaction_by_id(t_id):
    conn = get_conn()
    c = conn.cursor()
    c.execute("""
        SELECT t.*, COALESCE(c.name, '未分类') AS category_name
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.id = ?
    """, (t_id,))
    row = c.fetchone()
    conn.close()
    return dict(row) if row else None


def update_transaction(t_id, t_type, amount, category_id, date, description=''):
    conn = get_conn()
    c = conn.cursor()
    c.execute("""
        UPDATE transactions
        SET type=?, amount=?, category_id=?, date=?, description=?
        WHERE id=?
    """, (t_type, amount, category_id, date, description, t_id))
    conn.commit()
    conn.close()


def get_transactions_by_month(year, month, limit=200):
    conn = get_conn()
    c = conn.cursor()
    month_str = f"{year:04d}-{month:02d}%"
    c.execute("""
        SELECT t.id, t.type, t.amount, t.date, t.description,
               COALESCE(c.name, '未分类') AS category_name
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.date LIKE ?
        ORDER BY t.date DESC, t.id DESC
        LIMIT ?
    """, (month_str, limit))
    rows = [dict(r) for r in c.fetchall()]
    conn.close()
    return rows


def get_monthly_summary(year, month):
    conn = get_conn()
    c = conn.cursor()
    month_str = f"{year:04d}-{month:02d}%"
    c.execute("""
        SELECT
            COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0) AS total_income,
            COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0) AS total_expense
        FROM transactions
        WHERE date LIKE ?
    """, (month_str,))
    row = dict(c.fetchone())
    conn.close()
    row['balance'] = row['total_income'] - row['total_expense']
    return row
