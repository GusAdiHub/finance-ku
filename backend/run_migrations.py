"""Standalone script to execute database migration and seed data."""
import os
import sys

# Ensure backend root is in sys.path
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
if CURRENT_DIR not in sys.path:
    sys.path.insert(0, CURRENT_DIR)

import pymysql
from alembic import command
from alembic.config import Config
from sqlalchemy import inspect, text

from app.core.config import settings
from app.database.base import Base
from app.database.session import SessionLocal, engine
from app.seeds.default_categories import seed_default_categories
import app.models  # noqa: F401


def ensure_database_exists():
    """Ensure the target MySQL database exists prior to running migrations."""
    print(f"Connecting to MySQL server at {settings.DB_HOST}:{settings.DB_PORT} as {settings.DB_USER}...")
    try:
        connection = pymysql.connect(
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            charset="utf8mb4",
        )
        with connection.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{settings.DB_NAME}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            )
            print(f"Database '{settings.DB_NAME}' is ready.")
        connection.close()
    except Exception as exc:
        print(f"Error checking/creating database '{settings.DB_NAME}': {exc}")
        print("Continuing with existing connection attempt...")


def run_alembic_migrations():
    """Execute Alembic upgrade head to build all tables."""
    print("Running Alembic migrations (upgrade head)...")
    ini_path = os.path.join(CURRENT_DIR, "alembic.ini")
    alembic_cfg = Config(ini_path)
    alembic_cfg.set_main_option("script_location", os.path.join(CURRENT_DIR, "alembic"))
    alembic_cfg.set_main_option("sqlalchemy.url", settings.sync_database_url)

    try:
        command.upgrade(alembic_cfg, "head")
        print("Alembic migrations completed successfully.")
    except Exception as exc:
        print(f"Alembic command error: {exc}")
        print("Attempting fallback direct table creation using SQLAlchemy Base.metadata...")
        Base.metadata.create_all(bind=engine)
        try:
            command.stamp(alembic_cfg, "head")
            print("Successfully stamped database at 'head'.")
        except Exception as stamp_exc:
            print(f"Note on stamp: {stamp_exc}")


def seed_categories():
    """Run default category seeding."""
    print("Seeding default categories...")
    db = SessionLocal()
    try:
        count = seed_default_categories(db)
        print(f"Default categories processed. {count} new categories added.")
    finally:
        db.close()


def verify_tables():
    """Verify all tables in the database."""
    print("\nVerifying database schema...")
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"Found {len(tables)} tables in '{settings.DB_NAME}':")
    for t in sorted(tables):
        columns = inspector.get_columns(t)
        pks = inspector.get_pk_constraint(t).get("constrained_columns", [])
        fks = inspector.get_foreign_keys(t)
        print(f" - {t}: {len(columns)} columns, PK: {pks}, {len(fks)} FKs")


def main():
    print("=== Personal & Family Finance Tracker Database Migration ===")
    ensure_database_exists()
    run_alembic_migrations()
    seed_categories()
    verify_tables()
    print("=== Migration & Seeding Finished Successfully ===")


if __name__ == "__main__":
    main()
