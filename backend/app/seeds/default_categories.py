"""Seed data for default system categories."""
import uuid
from typing import List, Dict
from sqlalchemy.orm import Session
from app.models.category import Category

DEFAULT_SYSTEM_CATEGORIES: List[Dict[str, str]] = [
    # Income Categories
    {
        "name": "Gaji",
        "type": "income",
        "icon": "briefcase",
        "color": "#10B981",
    },
    {
        "name": "Bonus & THR",
        "type": "income",
        "icon": "gift",
        "color": "#059669",
    },
    {
        "name": "Bisnis & Usaha",
        "type": "income",
        "icon": "store",
        "color": "#047857",
    },
    {
        "name": "Investasi & Passive Income",
        "type": "income",
        "icon": "trending-up",
        "color": "#065F46",
    },
    {
        "name": "Hadiah & Hibah",
        "type": "income",
        "icon": "award",
        "color": "#34D399",
    },
    {
        "name": "Pemasukan Lainnya",
        "type": "income",
        "icon": "plus-circle",
        "color": "#6EE7B7",
    },
    # Expense Categories
    {
        "name": "Makanan & Minuman",
        "type": "expense",
        "icon": "utensils",
        "color": "#EF4444",
    },
    {
        "name": "Belanja Harian & Rumah Tangga",
        "type": "expense",
        "icon": "shopping-cart",
        "color": "#F97316",
    },
    {
        "name": "Tagihan & Utilitas",
        "type": "expense",
        "icon": "zap",
        "color": "#F59E0B",
    },
    {
        "name": "Transportasi & Bensin",
        "type": "expense",
        "icon": "car",
        "color": "#3B82F6",
    },
    {
        "name": "Pendidikan & Sekolah",
        "type": "expense",
        "icon": "book-open",
        "color": "#8B5CF6",
    },
    {
        "name": "Kesehatan & Medis",
        "type": "expense",
        "icon": "activity",
        "color": "#EC4899",
    },
    {
        "name": "Hiburan & Rekreasi",
        "type": "expense",
        "icon": "film",
        "color": "#6366F1",
    },
    {
        "name": "Zakat, Infaq & Donasi",
        "type": "expense",
        "icon": "heart",
        "color": "#14B8A6",
    },
    {
        "name": "Pakaian & Perawatan Diri",
        "type": "expense",
        "icon": "smile",
        "color": "#A855F7",
    },
    {
        "name": "Pengeluaran Lainnya",
        "type": "expense",
        "icon": "help-circle",
        "color": "#64748B",
    },
]


def seed_default_categories(db: Session) -> int:
    """Idempotently seed default system categories.

    Returns:
        int: Number of new categories created.
    """
    created_count = 0
    for item in DEFAULT_SYSTEM_CATEGORIES:
        existing = (
            db.query(Category)
            .filter(
                Category.name == item["name"],
                Category.type == item["type"],
                Category.is_system.is_(True),
            )
            .first()
        )
        if not existing:
            category = Category(
                id=str(uuid.uuid4()),
                name=item["name"],
                type=item["type"],
                icon=item["icon"],
                color=item["color"],
                is_system=True,
                user_id=None,
                group_id=None,
            )
            db.add(category)
            created_count += 1

    if created_count > 0:
        db.commit()
    return created_count


if __name__ == "__main__":
    from app.database.session import SessionLocal

    session = SessionLocal()
    try:
        count = seed_default_categories(session)
        print(f"Successfully seeded {count} default categories.")
    finally:
        session.close()
