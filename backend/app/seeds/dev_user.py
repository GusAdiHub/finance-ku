"""Seed data for a ready-to-use development account with sample transactions and group."""
import uuid
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.user import User
from app.models.category import Category
from app.models.finance_group import FinanceGroup
from app.models.group_member import GroupMember
from app.models.transaction import Transaction


def seed_dev_account(db: Session) -> User:
    """Create a default development user, sample family group, and initial transactions."""
    dev_email = "dev@sakukeluarga.id"
    existing_user = db.query(User).filter(User.email == dev_email).first()

    if existing_user:
        print(f"[*] Dev account already exists: {dev_email}")
        return existing_user

    print(f"[*] Creating dev account: {dev_email} ...")
    user_id = str(uuid.uuid4())
    dev_user = User(
        id=user_id,
        name="Budi Santoso",
        email=dev_email,
        password_hash=get_password_hash("Password123!"),
        is_active=True,
    )
    db.add(dev_user)
    db.flush()

    # 1. Create a sample Event / Team Group
    group_id = str(uuid.uuid4())
    sample_group = FinanceGroup(
        id=group_id,
        name="Panitia Event & Proyek",
        description="[ANGGARAN:10000000] Kas operasional dan bukti nota belanja panitia event",
        created_by_user_id=dev_user.id,
        is_active=True,
    )
    db.add(sample_group)
    db.flush()

    # 2. Add dev user as Owner of the family group
    membership = GroupMember(
        id=str(uuid.uuid4()),
        group_id=group_id,
        user_id=dev_user.id,
        role="owner",
        is_active=True,
    )
    db.add(membership)
    db.flush()

    # 3. Fetch system categories for initial sample transactions
    gaji_cat = db.query(Category).filter(Category.name.ilike("%gaji%"), Category.is_system == True).first()  # noqa: E712
    makanan_cat = db.query(Category).filter(Category.name.ilike("%makanan%"), Category.is_system == True).first()  # noqa: E712
    belanja_cat = db.query(Category).filter(Category.name.ilike("%belanja%"), Category.is_system == True).first()  # noqa: E712
    tagihan_cat = db.query(Category).filter(Category.name.ilike("%tagihan%"), Category.is_system == True).first()  # noqa: E712
    transport_cat = db.query(Category).filter(Category.name.ilike("%transport%"), Category.is_system == True).first()  # noqa: E712

    now = datetime.now(timezone.utc)

    # Sample Personal Transactions
    if gaji_cat:
        db.add(
            Transaction(
                id=str(uuid.uuid4()),
                type="income",
                amount=Decimal("12500000.00"),
                category_id=gaji_cat.id,
                transaction_date=now - timedelta(days=5),
                description="Gaji Bulanan",
                owner_user_id=dev_user.id,
                created_by_user_id=dev_user.id,
                input_method="manual",
            )
        )

    if makanan_cat:
        db.add(
            Transaction(
                id=str(uuid.uuid4()),
                type="expense",
                amount=Decimal("45000.00"),
                category_id=makanan_cat.id,
                transaction_date=now - timedelta(days=1),
                description="Makan Siang Nasi Padang",
                owner_user_id=dev_user.id,
                created_by_user_id=dev_user.id,
                input_method="voice",
            )
        )

    if transport_cat:
        db.add(
            Transaction(
                id=str(uuid.uuid4()),
                type="expense",
                amount=Decimal("100000.00"),
                category_id=transport_cat.id,
                transaction_date=now - timedelta(days=2),
                description="Bensin Pertamax Motor",
                owner_user_id=dev_user.id,
                created_by_user_id=dev_user.id,
                input_method="manual",
            )
        )

    # Sample Family Group Shared Transactions
    if belanja_cat:
        db.add(
            Transaction(
                id=str(uuid.uuid4()),
                type="expense",
                amount=Decimal("1850000.00"),
                category_id=belanja_cat.id,
                transaction_date=now - timedelta(days=3),
                description="Belanja Bulanan Supermarket",
                group_id=group_id,
                created_by_user_id=dev_user.id,
                input_method="ocr",
            )
        )

    if tagihan_cat:
        db.add(
            Transaction(
                id=str(uuid.uuid4()),
                type="expense",
                amount=Decimal("550000.00"),
                category_id=tagihan_cat.id,
                transaction_date=now - timedelta(days=4),
                description="Tagihan Listrik PLN & Internet",
                group_id=group_id,
                created_by_user_id=dev_user.id,
                input_method="manual",
            )
        )

    db.commit()
    print("[+] Dev account, group, and sample transactions successfully seeded!")
    return dev_user


if __name__ == "__main__":
    from app.database.session import SessionLocal

    session = SessionLocal()
    try:
        seed_dev_account(session)
    finally:
        session.close()
